#!/bin/sh
#SET WORKING DIRECTORY AS FOLDER WITH TWO REPOSITORIES

cd hra-azimuth-predictions/hubmap-kidney;
python3 prepare_metadata.py hubmap-datasets-metadata.tsv;
python3 download.py $1;
cd ..;
mkdir hubmap-kidney/reference-data;
curl -o hubmap-kidney/reference-data/human-kidney.Rds https://zenodo.org/record/5181818/files/ref.Rds;
cd hubmap-kidney
Rscript run_pipeline.R;
cd ..;
cd ..;

mkdir tissue-bar-graphs/azimuth-predictions;
cp -R hra-azimuth-predictions/ tissue-bar-graphs/azimuth-predictions/;
cd tissue-bar-graphs;
npm install utils/package.json;
cd utils;
node azimuth_aggregator.js;
cd ..;
python3 azimuth-predictions/hubmap-kidney/append_donor_metadata.py;
cd ..;



