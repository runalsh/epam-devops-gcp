
project_id = ${GCP_PROJECT}
credentials = "credentials.json"
region     = "europe-west4"
zones              = ["europe-west4-a", "europe-west4-b"]
name               = "epam-py-cluster"
machine_type       = "e2-small"
initial_node_count = 1
min_count          = 1
max_count          = 2
disk_size_gb       = 10
service_account    = "sa-533@handy-station-339318.iam.gserviceaccount.com"
imagename		= "epamapp"
postgres_version = "POSTGRES_13_4"
db_name = "wandb"
master_user_password = ${GCP_PROJECT}
master_user_name =  ${GCP_PROJECT}
machine_type_db = "db-f1-micro"
