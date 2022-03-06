import axios from 'axios'
import papaparse from 'papaparse'
import fs from 'fs'

axios.defaults.baseURL = 'https://cells.ucsc.edu/'
const master = (await axios.get(`dataset.json`)).data

const datasets = await fetchNestedDatasets(master.datasets);

async function fetchNestedDatasets(datasets) {
  const collection = []
  for (const dataset of datasets) {
    if (dataset.isCollection) {
      try {
        const response = await axios.get(`${dataset.name}/dataset.json`)
        const nestedDatasets = response.data.datasets
        const innerDatasets = await fetchNestedDatasets(nestedDatasets)
        collection.push(...innerDatasets)
      } catch (err) {
        console.error(err)
      }
    } else {
      collection.push({
        dataset_id: dataset.name,
        dataset_short_label: dataset.shortLabel,
        sample_count: dataset.sampleCount,
        organ: (Array.isArray(dataset.body_parts) && dataset.body_parts.join('; ')) || null
      })
    }
  }

  return collection
}

const csvData = papaparse.unparse(datasets)

if (!fs.existsSync('data')) {
  fs.mkdirSync('data')
}
fs.writeFileSync('data/datasets.csv', csvData, { encoding: 'utf-8', flag: 'w+' })
