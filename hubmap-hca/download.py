import logging
import os
import sys
from csv import reader
from urllib.error import HTTPError
from requests import get

if __name__ == '__main__':
    os.makedirs('logs', exist_ok=True)
    log_format = "%(levelname)s %(asctime)s - %(message)s"
    logging.basicConfig(
        filename = 'logs/download.log',
        filemode = 'a',
        format = log_format,
        level = logging.DEBUG)
    logger = logging.getLogger()

    logger.info('Initiated')
    if 'HUBMAP_TOKEN' in os.environ:
        hubmap_token = os.getenv('HUBMAP_TOKEN')
    else:
        if len(sys.argv) < 2:
            logging.error('HUBMAP_TOKEN is not set/provided. Exiting.')
            sys.exit(-1)
        else:
            hubmap_token = sys.argv[1]
    root_dir = 'data'
    target_files = ['raw_expr.h5ad', 'secondary_analysis.h5ad']

    with open('datasets.csv', newline='') as csvfile:
        os.makedirs(root_dir, exist_ok=True)
        os.chdir(root_dir)
        datasets = reader(csvfile, delimiter=',')

        for dataset_hubmap_id, dataset_uuid in datasets:
            os.makedirs(dataset_hubmap_id, exist_ok=True)
            for target in target_files:
                api_url = 'https://assets.hubmapconsortium.org/{}/{}?token={}'.format(dataset_uuid, target, hubmap_token)
                file_path = os.path.join(dataset_hubmap_id, target)

                if os.path.exists(file_path):
                    logger.info(f'Skipped dataset: {file_path}')
                    continue

                logger.info(f'Downloading dataset: {file_path}')
                response = get(api_url)
                try:
                    response.raise_for_status()
                    with open(file_path, 'wb') as file:
                        file.write(response.content)
                        file.close()
                        logger.info(f'Created file: {file_path}')
                except HTTPError:
                    logger.error(f'Error downloading dataset: {file_path}')
                except BaseException as e:
                    logger.error(e)
    
    logger.info('Completed')
