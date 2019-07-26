variable public_key_path {
  description = "Path to the public key used to connect to instance"
}

variable zone {
  description = "Zone"
  default     = "europe-west1-b"
}

variable "db-ip" {
  description = "IP of mongodb"
  default     = "localhost"
}

variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-base-1562920483"
}
