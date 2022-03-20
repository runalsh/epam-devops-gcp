provider "google" {
  credentials = var.credentials
  project     = var.project_id
  region      = var.region
  # version = "~> 4.40.0"


}

variable "credentials" {
  type        = string
  description = "Location of the credential keyfile."
}

variable "project_id" {
  type        = string
  description = "The project ID to create the cluster."
}

variable "region" {
  type        = string
  description = "The region to create the cluster."
}

variable "zones" {
  type        = list(string)
  description = "The zones to create the cluster."
}

variable "name" {
  type        = string
  description = "The name of the cluster."
}

variable "machine_type" {
  type        = string
  description = "Type of the node compute engines."
}

variable "min_count" {
  type        = number
  description = "Minimum number of nodes in the NodePool. Must be >=0 and <= max_node_count."
}

variable "max_count" {
  type        = number
  description = "Maximum number of nodes in the NodePool. Must be >= min_node_count."
}

variable "disk_size_gb" {
  type        = number
  description = "Size of the node's disk."
}

variable "service_account" {
  type        = string
  description = "The service account to run nodes as if not overridden in `node_pools`. The create_service_account variable default value (true) will cause a cluster-specific service account to be created."
}

variable "initial_node_count" {
  type        = number
  description = "The number of nodes to create in this cluster's default node pool."
}

variable "postgres_version" {
  description = "The engine version of the database, e.g. `POSTGRES_13_4`. See https://cloud.google.com/sql/docs/features for supported versions."
  type        = string
  default     = "POSTGRES_13"
}

variable "machine_type_db" {
  description = "The machine type to use, see https://cloud.google.com/sql/pricing for more details"
  type        = string
  default     = "db-f1-micro"
}

variable "db_name" {
  description = "Name for the db"
  type        = string
}

variable "dbuser" {
  description = "Name for the db user"
  type        = string
}

variable "dbpasswd" {
  description = "password  for the db"
  type        = string
}


resource "google_storage_bucket" "state-bucket" {
  name     = var.project_id
  location = "${var.region}"

  versioning {
    enabled = true
  }
  # force_destroy = true

  lifecycle_rule {
    condition {
      age = 4
    }
    action {
      type = "Delete"
    }
  }
}



# здесь нельзя встаить вариэйблс. почему? да хз
# можно обойти создать вручную через gcloud до инициализации terra, надо подумать как ещё 
# todo

#test
#resource "random_id" "suffix" {
#  byte_length               = 4
#}

terraform {
  backend "gcs" {
    bucket          = "handy-station-339318"
    prefix          = "/terraform.tfstate"
    credentials     = "credentials.json"
  }
}


module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = var.project_id
  region                     = var.region
  zones                      = var.zones
  name                       = var.name
  network                    = "default"
  subnetwork                 = "default"
  ip_range_pods              = ""
  ip_range_services          = ""
  http_load_balancing        = false
  horizontal_pod_autoscaling = false
  # kubernetes_dashboard       = true
  network_policy             = true
  remove_default_node_pool = false

  node_pools = [
    {
      name               = "pyapp-node-default"
      machine_type       = var.machine_type
      min_count          = var.min_count
      max_count          = var.max_count
      disk_size_gb       = var.disk_size_gb
      disk_type          = "pd-standard"
      image_type         = "COS"
      auto_repair        = true
      auto_upgrade       = true
      service_account    = var.service_account
      preemptible        = false
      initial_node_count = var.initial_node_count
    }
  ]
}


 resource "google_sql_database_instance" "database" {
      name = var.db_name
      database_version = var.postgres_version
      region = var.region
      depends_on = [
        "google_service_networking_connection.private_vpc_connection"
        ]
      settings {
          tier = var.machine_type_db
          ip_configuration {
            # ipv4_enabled = true
            # authorized_networks {
              # name = "all"
              # value = "0.0.0.0/0"
              
            ipv4_enabled = "false"
            private_network = "${google_compute_network.private_network.self_link}"
            }
          }
      deletion_protection = false
      # depends_on = [
        # "google_project_services.vpc"
      # ]
    }

resource "google_sql_user" "user" {
  name     = var.dbuser
  instance = "${google_sql_database_instance.database.name}"
  password = var.dbpasswd

  depends_on = [
    "google_sql_database_instance.database"
  ]
}

resource "google_sql_database" "database" {
  name     = "pydb"
  instance = "${google_sql_database_instance.database.name}"
}

resource "google_compute_network" "private_network" {
  project     = var.project_id
  name       = "default"
  auto_create_subnetworks = true
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address = "10.27.0.3"
  address_type = "INTERNAL"
  prefix_length = 16
  network       = "${google_compute_network.private_network.self_link}"
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network       = "${google_compute_network.private_network.self_link}"
  service       = "servicenetworking.googleapis.com"
  reserved_peering_ranges = ["${google_compute_global_address.private_ip_address.name}"]
}

resource "google_monitoring_dashboard" "dashboard" {
	dashboard_json = file("./dashboard.json")
}


output "private_ip_address" {
    value = "${ google_sql_database_instance.database.private_ip_address }"
}
