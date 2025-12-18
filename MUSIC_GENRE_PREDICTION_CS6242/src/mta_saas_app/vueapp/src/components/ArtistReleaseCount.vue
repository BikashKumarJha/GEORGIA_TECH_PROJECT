<template>
    <h4> Artist with top music release count </h4>
    <h5>Enter count</h5>
    <input v-model.lazy="Limit" align="left"> {{ number }}
    <div v-if="DataTable">
        <table>
            <thead>
                <tr>
                    <th>Artist</th>
                    <th>Music Release Count</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="row in DataTable" :key="row.name">
                    <td>{{ row.name }}</td>
                    <td>{{ row.release_count }}</td>
                </tr>
            </tbody>
        </table>
    </div>
</template>

<script lang="js">
    import axios from 'axios';
    import { inject, defineComponent } from 'vue';

    export default defineComponent({
        setup() {
            const config = inject('config')
            return { config }
        },
        data() {
            return {
                DataTable: [],
                Limit: null
            };
        },
        created() {
        },
        watch: {
            Limit: 'fetchData'
        },
        methods: {
            fetchData() {
                this.DataTable = null;
                axios.get(`${this.config.MusicbrainzUrl}GetArtistReleaseCount/${this.Limit}`)
                    .then(response => {
                        this.DataTable = response.data;
                        return;
                    })
                    .catch(err => console.log(err.message));
            }
            
        }
    });
</script>
