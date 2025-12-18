using Microsoft.AspNetCore.Mvc;
using Npgsql;
using System.Data;
using Newtonsoft.Json;
using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace webapi.Controllers
{
    [Route("[controller]/[action]")]
    [ApiController]
    public class MusicbrainzController : ControllerBase
    {
        private readonly ILogger<MusicbrainzController> _logger;
        private readonly IConfiguration _configuration;
        private readonly InferenceSession _session;
        public MusicbrainzController(ILogger<MusicbrainzController> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;

            //string modelPath = Path.Combine(Environment.CurrentDirectory, "best_svm_model.onnx");
            string modelPath = Path.Combine(AppContext.BaseDirectory, "hgb_model.onnx");
            _logger.LogError($"Output: {modelPath}");
            _session = new InferenceSession(modelPath);


        }

        private DataTable QueryDatabase(string query)
        {
            string? postGreSqlDataSource = _configuration.GetConnectionString("MusicbrainzDb");
            DataTable dataTable = new DataTable();
            try
            {
                using (var connection = new NpgsqlConnection(postGreSqlDataSource))
                {
                    connection.Open();
                    using (var command = new NpgsqlCommand(query, connection))
                    {
                        //command.Parameters.AddWithValue("@limit", limit);
                        using (var adapter = new NpgsqlDataAdapter(command))
                        {
                            adapter.Fill(dataTable);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message);
                throw;
            }

            return dataTable;
        }

        [HttpPost("{artistId}")]
        public ActionResult RunModel(int artistId)
        {
            string query = $@"SELECT * FROM  mta WHERE id = {artistId}";
            try
            {
                DataTable dataTable = this.QueryDatabase(query);

                if (dataTable.Rows.Count > 0)
                {
                    dataTable.Columns["lc"].ColumnName = "listenCount";
                    dataTable.Columns["uc"].ColumnName = "userCount";
                    dataTable.Columns["cc"].ColumnName = "collaborationCount";
                    dataTable.Columns["rc"].ColumnName = "releaseCount";
                    dataTable.Columns.Add("success probability", typeof(string));
                    var inputData = new float[]
                    {
                        float.Parse(dataTable.Rows[0]["type"].ToString()),
                        float.Parse(dataTable.Rows[0]["area"].ToString()),
                        float.Parse(dataTable.Rows[0]["gender"].ToString()),
                        float.Parse(dataTable.Rows[0]["userCount"].ToString()),
                        float.Parse(dataTable.Rows[0]["listenCount"].ToString()),
                        float.Parse(dataTable.Rows[0]["collaborationCount"].ToString()),
                        float.Parse(dataTable.Rows[0]["releaseCount"].ToString())

                    };
                    ;
                    var tensor = new DenseTensor<float>(inputData, new[] { 1, 7 }); // 1x7 tensor
                    var inputs = new List<NamedOnnxValue>
                    {
                        NamedOnnxValue.CreateFromTensor("float_input", tensor)
                    };
                    using IDisposableReadOnlyCollection<DisposableNamedOnnxValue> outputs = _session.Run(inputs);

                    DisposableNamedOnnxValue labelOutput = outputs[0];
                    Tensor<string> labelTensor = (Tensor<string>)labelOutput.AsTensor<string>();
                    string predictedLabel = labelTensor[0];
                    _logger.LogError($"Output label: {predictedLabel}");
                    dataTable.Rows[0]["success probability"] = predictedLabel;
                }

                return Ok(JsonConvert.SerializeObject(dataTable));
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpGet("{search}")]
        public ActionResult GetArtists(string search)
        {
            string query = $@"            
            SELECT 
                id, name
            FROM 
                mta
            WHERE
                LOWER(name) LIKE LOWER('%{search}%')
            ORDER BY 
                name DESC";

            try
            {
                DataTable dataTable = this.QueryDatabase(query);

                return Ok(JsonConvert.SerializeObject(dataTable));
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpGet("{limit}")]
        public ActionResult GetArtistReleaseCount(int limit = 10)
        {
            string query = $@"            
            SELECT 
                a.name, COUNT(r.id) AS release_count
            FROM 
                artist a
            JOIN 
                release_group rg ON a.id = rg.artist_credit
            JOIN 
                release r ON rg.id = r.release_group
            WHERE 
                a.name != 'Various Artists' AND a.name != '[unkown]'
            GROUP BY 
                a.name
            ORDER BY 
                release_count DESC
            LIMIT 
                {limit}";

            try
            {
                DataTable dataTable = this.QueryDatabase(query);

                return Ok(JsonConvert.SerializeObject(dataTable));
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpGet("{limit}")]
        public ActionResult GetTop150Artists(int limit = 10)
        {
            string query = $@"            
            SELECT 
                name, gross_revenue, tickets_sold
            FROM 
                pollstar_top150_artist
            LIMIT 
                {limit}";

            try
            {
                DataTable dataTable = this.QueryDatabase(query);

                return Ok(JsonConvert.SerializeObject(dataTable));
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpGet("{limit}")]
        public ActionResult GetArtistCollaboration(int limit = 25)
        {
            string query = $@"
                WITH Collaborations AS (
                    SELECT
                        acn.artist_credit
                    FROM 
                        artist_credit_name acn
                    GROUP BY 
                        acn.artist_credit
                    HAVING 
                        COUNT(acn.artist) > 1
                ),

                Pairs AS (
                    SELECT
                        a1.name AS artist1_name, a1.id as id1, a2.id as id2,
                        a2.name AS artist2_name
                    FROM 
                        Collaborations c
                    JOIN 
                        artist_credit_name acn1 ON acn1.artist_credit = c.artist_credit
                    JOIN 
                        artist_credit_name acn2 ON acn2.artist_credit = c.artist_credit AND acn1.artist < acn2.artist
                    JOIN 
                        artist a1 ON acn1.artist = a1.id
                    JOIN 
                        artist a2 ON acn2.artist = a2.id
                )

                SELECT 
                    id1, id2, artist1_name, artist2_name, COUNT(*) as collaboration_count
                FROM 
                    Pairs
                GROUP BY 
                    artist1_name, artist2_name, id1, id2
                ORDER BY 
                    collaboration_count DESC, artist1_name, artist2_name
                LIMIT {limit}
            ";

            try
            {
                DataTable dataTable = this.QueryDatabase(query);

                return Ok(JsonConvert.SerializeObject(dataTable));
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpGet("{limit}")]
        public ActionResult GetArtistListenCount(int limit = 20)
        {
            string query = $@"
                SELECT 
                    name, lc
                FROM 
                    musicbrainz.mta
                ORDER BY 
                    lc DESC
                LIMIT 
                    {limit}
            ";

            try
            {
                DataTable dataTable = this.QueryDatabase(query);

                return Ok(JsonConvert.SerializeObject(dataTable));
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpGet("{limit}")]
        public ActionResult GetArtistUserCount(int limit = 20)
        {
            string query = $@"
                SELECT 
                    name, uc
                FROM 
                    musicbrainz.mta
                ORDER BY 
                    uc DESC
                LIMIT 
                    {limit}
            ";

            try
            {
                DataTable dataTable = this.QueryDatabase(query);

                return Ok(JsonConvert.SerializeObject(dataTable));
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpGet("{limit}")]
        public ActionResult GetCountryArtistCount(int limit = 25)
        {
            string query = $@"
                SELECT 
                    a1.name AS country_name, COUNT(distinct ar.id) AS artist_count
                FROM 
                    artist ar
                JOIN 
                    area a1 ON ar.area = a1.id
                GROUP BY 
                    a1.name
                ORDER BY 
                    artist_count DESC
                limit 
                    {limit}
            ";

            try
            {
                DataTable dataTable = this.QueryDatabase(query);

                return Ok(JsonConvert.SerializeObject(dataTable));
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpGet("{limit}")]
        public ActionResult GetCountryReleaseCount(int limit = 25)
        {
            string query = $@"
                SELECT 
                    a.name AS country_name, COUNT(rc.release) AS release_count
                FROM 
                    release_country rc
                JOIN 
                    country_area ca ON rc.country = ca.area
                JOIN 
                    area a ON ca.area = a.id
                JOIN 
                    area_type at ON a.type = at.id
                WHERE 
                    at.name = 'Country'
                GROUP BY 
                    a.name
                ORDER BY 
                    release_count DESC
                limit 
                    {limit}
            ";

            try
            {
                DataTable dataTable = this.QueryDatabase(query);

                return Ok(JsonConvert.SerializeObject(dataTable));
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }
    }

}
