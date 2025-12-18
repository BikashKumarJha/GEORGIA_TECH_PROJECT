import { useEffect, useState } from 'react';
import {
  MapContainer,
  TileLayer,
  useMapEvents,
  GeoJSON,
  Popup
} from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import './App.css';

const stateLookup = {
  "01": "Alabama", "02": "Alaska", "04": "Arizona", "05": "Arkansas", "06": "California",
  "08": "Colorado", "09": "Connecticut", "10": "Delaware", "11": "District of Columbia", "12": "Florida",
  "13": "Georgia", "15": "Hawaii", "16": "Idaho", "17": "Illinois", "18": "Indiana",
  "19": "Iowa", "20": "Kansas", "21": "Kentucky", "22": "Louisiana", "23": "Maine",
  "24": "Maryland", "25": "Massachusetts", "26": "Michigan", "27": "Minnesota", "28": "Mississippi",
  "29": "Missouri", "30": "Montana", "31": "Nebraska", "32": "Nevada", "33": "New Hampshire",
  "34": "New Jersey", "35": "New Mexico", "36": "New York", "37": "North Carolina", "38": "North Dakota",
  "39": "Ohio", "40": "Oklahoma", "41": "Oregon", "42": "Pennsylvania", "44": "Rhode Island",
  "45": "South Carolina", "46": "South Dakota", "47": "Tennessee", "48": "Texas", "49": "Utah",
  "50": "Vermont", "51": "Virginia", "53": "Washington", "54": "West Virginia", "55": "Wisconsin", "56": "Wyoming"
};

function MapEvents({ onZoomChange }) {
  useMapEvents({
    zoomend: (e) => onZoomChange(e.target.getZoom())
  });
  return null;
}

export default function App() {
  const [data, setData] = useState([]);
  const [geoJson, setGeoJson] = useState(null);
  const [stateGeoJson, setStateGeoJson] = useState(null);
  const [selectedState, setSelectedState] = useState('');
  const [selectedRegion, setSelectedRegion] = useState('');
  const [sortBy, setSortBy] = useState('Total Population');
  const [sortOrder, setSortOrder] = useState('desc');
  const [zoomLevel, setZoomLevel] = useState(4);
  const [clickedPopup, setClickedPopup] = useState(null);

  useEffect(() => {
    fetch('/food_insecurity_county_data.json').then(res => res.json()).then(setData);
    fetch('/us-counties.geojson').then(res => res.json()).then(setGeoJson);
    fetch('/us-states.json').then(res => res.json()).then(setStateGeoJson);
  }, []);

  const regions = [...new Set(data.map(d => d.region))];
  const states = [...new Set(data.map(d => d.State))];

  const filtered = data.filter(d => {
    return (!selectedRegion || d.region === selectedRegion) &&
           (!selectedState || d.State === selectedState);
  });

  const sorted = [...filtered].sort((a, b) => {
    const dir = sortOrder === 'asc' ? 1 : -1;
    return (a[sortBy] ?? 0) > (b[sortBy] ?? 0) ? dir : -dir;
  });

  const toggleSort = (field) => {
    if (sortBy === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortBy(field);
      setSortOrder('desc');
    }
  };

  const getStateAverage = (stateName) => {
    const stateData = data.filter(d => d.State === stateName);
    const avg = stateData.reduce((sum, d) => sum + d['Food Desert Score'], 0) / stateData.length;
    return avg.toFixed(2);
  };

  const getColor = (score) => {
    if (score === undefined || isNaN(score) || score <= 0) return '#aaa';
    if (score < 0.15) return '#3182bd';
    if (score < 0.25) return '#6baed6';
    if (score < 0.35) return '#fd8d3c';
    if (score < 0.45) return '#f03b20';
    return '#bd0026';
  };

  const scoreMap = {};
  for (let row of data) {
    const key = String(row.cfips).padStart(5, '0');
    if (key && !isNaN(row['Food Desert Score'])) {
      scoreMap[key] = row['Food Desert Score'];
    }
  }

  const styleFeature = (feature) => {
    const fips = feature.properties?.GEOID;
    const score = scoreMap[fips];
    return {
      fillColor: getColor(score),
      fillOpacity: 0.7,
      color: '#555',
      weight: 0.4,
    };
  };

  const onEachFeature = (feature, layer) => {
    const fips = feature.properties?.GEOID;
    const score = scoreMap[fips];
    const name = feature.properties?.NAME || 'Unknown County';
    const stateFIPS = feature.properties?.STATEFP;
    const state = stateLookup[stateFIPS] || 'Unknown State';

    if (zoomLevel > 6 && score !== undefined) {
      layer.on('click', () => {
        setClickedPopup({
          latlng: layer.getBounds().getCenter(),
          content: `<div class="popup-content"><strong>${name}, ${state}</strong><br/>Score: ${score.toFixed(2)}</div>`
        });
      });
    }
  };

  const onEachStateFeature = (feature, layer) => {
    const name = feature.properties?.name || 'Unknown State';
    const avg = getStateAverage(name);
    layer.on('click', () => {
      setClickedPopup({
        latlng: layer.getBounds().getCenter(),
        content: `<div class="popup-content"><strong>${name}</strong><br/>Avg Score: ${avg}</div>`
      });
    });
  };

  const stateStyle = (feature) => {
    const name = feature.properties?.name;
    const avg = parseFloat(getStateAverage(name));
    return {
      fillColor: getColor(avg),
      fillOpacity: 0.7,
      color: '#666',
      weight: 1
    };
  };

  return (
    <div style={{ fontFamily: 'Arial, sans-serif', padding: '1rem', backgroundColor: '#121212', color: '#eee', minHeight: '100vh' }}>
      <header style={{ textAlign: 'center', marginBottom: '1rem' }}>
        <h1 style={{ fontSize: '2rem', fontWeight: 'bold' }}>🌎 Hunger View USA</h1>
        <p style={{ color: '#ccc' }}>Track food insecurity across the United States</p>
      </header>

      <div style={{ height: '60vh', marginBottom: '2rem', borderRadius: '1rem', overflow: 'hidden', boxShadow: '0 2px 6px rgba(0,0,0,0.3)' }}>
        <MapContainer center={[39.8283, -98.5795]} zoom={4} style={{ height: '100%', width: '100%' }}>
          <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" attribution="&copy; OpenStreetMap contributors" />
          <MapEvents onZoomChange={setZoomLevel} />
          {zoomLevel <= 6 && stateGeoJson && (
            <GeoJSON data={stateGeoJson} style={stateStyle} onEachFeature={onEachStateFeature} />
          )}
          {zoomLevel > 6 && geoJson && (
            <GeoJSON data={geoJson} style={styleFeature} onEachFeature={onEachFeature} />
          )}
          {clickedPopup && (
            <Popup position={clickedPopup.latlng} onClose={() => setClickedPopup(null)}>
              <div dangerouslySetInnerHTML={{ __html: clickedPopup.content }} />
            </Popup>
          )}
            {/*Legend Control */}
          <div className="leaflet-bottom leaflet-left">
            <div className="leaflet-control leaflet-bar legend">
              <h4>Food Desert Score</h4>
              <div><i style={{ background: '#3182bd' }}></i> 0 - 0.15</div>
              <div><i style={{ background: '#6baed6' }}></i> 0.15 - 0.25</div>
              <div><i style={{ background: '#fd8d3c' }}></i> 0.25 - 0.35</div>
              <div><i style={{ background: '#f03b20' }}></i> 0.35 - 0.45</div>
              <div><i style={{ background: '#bd0026' }}></i> 0.45+</div>
            </div>
          </div>
        </MapContainer>
      </div>

      <div style={{ display: 'flex', justifyContent: 'center', gap: '1rem', flexWrap: 'wrap', marginBottom: '1rem' }}>
        <select value={selectedRegion} onChange={e => setSelectedRegion(e.target.value)} style={{ padding: '0.5rem', borderRadius: '0.5rem', backgroundColor: '#222', color: '#eee' }}>
          <option value=''>All Regions</option>
          {regions.map(r => <option key={r} value={r}>{r}</option>)}
        </select>

        <select value={selectedState} onChange={e => setSelectedState(e.target.value)} style={{ padding: '0.5rem', borderRadius: '0.5rem', backgroundColor: '#222', color: '#eee' }}>
          <option value=''>All States</option>
          {states.map(s => <option key={s} value={s}>{s}</option>)}
        </select>
      </div>

      <div style={{
        background: '#1e1e1e',
        borderRadius: '1rem',
        boxShadow: '0 2px 8px rgba(0,0,0,0.5)',
        maxHeight: '400px',
        overflowY: 'scroll',
        padding: '1rem'
      }}>
        <table style={{ width: '100%', fontSize: '0.9rem', borderCollapse: 'collapse', color: '#eee' }}>
          <thead style={{ position: 'sticky', top: 0, background: '#2a2a2a', borderBottom: '1px solid #444' }}>
            <tr>
              {['State', 'County', 'Total Population', 'Food Desert Score', 'Total SNAP Households', 'Households Without Vehicle'].map(col => (
                <th key={col} onClick={() => toggleSort(col)} style={{ padding: '0.5rem', cursor: 'pointer', textAlign: 'left' }}>
                  {col} {sortBy === col ? (sortOrder === 'asc' ? '▲' : '▼') : ''}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {sorted.map((row, i) => (
              <tr key={i} style={{ borderBottom: '1px solid #333' }}>
                <td style={{ padding: '0.5rem' }}>{row.State}</td>
                <td style={{ padding: '0.5rem' }}>{row.County}</td>
                <td style={{ padding: '0.5rem' }}>{row['Total Population'].toLocaleString()}</td>
                <td style={{ padding: '0.5rem' }}>{row['Food Desert Score'].toFixed(2)}</td>
                <td style={{ padding: '0.5rem' }}>{row['Total SNAP Households'].toLocaleString()}</td>
                <td style={{ padding: '0.5rem' }}>{row['Households Without Vehicle'].toLocaleString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
