import axios from "axios";

const BASE_URL = "https://localhost:7069/Musicbrainz/";

export const queryArtistReleases = (limit) => {
  return axios
    .get(`${BASE_URL}GetArtistReleaseCount/${limit}`)
    .then((response) => {
      return response.data?.map((item) => {
        return { name: item.name, count: item.release_count };
      });
    })
    .catch((err) => {
      console.log(err.message);
      return [];
    });
};

export const queryTopArtistsByRevenue = (limit) => {
  return axios
    .get(`${BASE_URL}GetTop150Artists/${limit}`)
    .then((response) => {
      return response.data?.map((item) => {
        return { name: item.name, count: item.gross_revenue };
      });
    })
    .catch((err) => {
      console.log(err.message);
      return [];
    });
};

export const queryTopArtistsByTicketsSold = (limit) => {
  return axios
    .get(`${BASE_URL}GetTop150Artists/${limit}`)
    .then((response) => {
      return response.data?.map((item) => {
        return { name: item.name, count: item.tickets_sold };
      });
    })
    .catch((err) => {
      console.log(err.message);
      return [];
    });
};

export const queryArtistListeners = (limit) => {
  return axios
    .get(`${BASE_URL}GetArtistListenCount/${limit}`)
    .then((response) => {
      return response.data?.map((item) => {
        return { name: item.name, count: item.lc };
      });
    })
    .catch((err) => {
      console.log(err.message);
      return [];
    });
};

export const queryArtistUsers = (limit) => {
  return axios
    .get(`${BASE_URL}GetArtistUserCount/${limit}`)
    .then((response) => {
      return response.data?.map((item) => {
        return { name: item.name, count: item.uc };
      });
    })
    .catch((err) => {
      console.log(err.message);
      return [];
    });
};

export const queryCountryArtist = (limit) => {
  return axios
    .get(`${BASE_URL}GetCountryArtistCount/${limit}`)
    .then((response) => {
      return response.data?.map((item) => {
        return { name: item.country_name, count: item.artist_count };
      });
    })
    .catch((err) => {
      console.log(err.message);
      return [];
    });
};

export const queryCountryReleases = (limit) => {
  return axios
    .get(`${BASE_URL}GetCountryReleaseCount/${limit}`)
    .then((response) => {
      return response.data?.map((item) => {
        return { name: item.country_name, count: item.release_count };
      });
    })
    .catch((err) => {
      console.log(err.message);
      return [];
    });
};

export const queryArtistCollaboration = (limit) => {
  return axios
    .get(`${BASE_URL}GetArtistCollaboration/${limit}`)
    .then((response) => {
      return response.data?.map((item) => {
        return {
          source: {
            id: item.id1,
            name: item.artist1_name,
          },
          target: {
            id: item.id2,
            name: item.artist2_name,
          },
          value: item.collaboration_count,
        };
      });
    })
    .catch((err) => {
      console.log(err.message);
      return [];
    });
};

export const queryArtists = (searchQuery) => {
  return axios
    .get(`${BASE_URL}GetArtists/${searchQuery}`)
    .then((response) => {
      return response.data;
    })
    .catch((err) => {
      console.log(err.message);
      return [];
    });
};

export const runModel = (artist_id) => {
  return axios
    .post(`${BASE_URL}RunModel/${artist_id}`)
    .then((response) => {
      return response.data;
    })
    .catch((err) => {
      console.log(err.message);
      return {};
    });
};
