





resource "google_bigquery_dataset" "pdf_redaction" {
  dataset_id    = "pdf_redaction${local.app_suffix_underscore}"
  friendly_name = "PDF Redaction Dataset"
  description   = "This dataset contains data related to the PDF Redaction application"
  location      = var.network_region
    project      = google_project.demo_project_pdf.project_id
  depends_on = [
    time_sleep.wait_build_image,
  ]
}

data "template_file" "bq_table_findings" {
  template = file("mod-pdf-redaction/templates/bq-table-findings.json")
  depends_on = [
    time_sleep.wait_build_image,
  ]
}

resource "google_bigquery_table" "findings" {
  dataset_id          = google_bigquery_dataset.pdf_redaction.dataset_id
  table_id            = "findings"
  project      = google_project.demo_project_pdf.project_id
  deletion_protection = false
  schema              = data.template_file.bq_table_findings.rendered

  depends_on = [
    time_sleep.wait_build_image,
  ]
}