provider "aws" {
  region = "us-east-1"
}

# S3 Bucket for AWS Data Exports
resource "aws_s3_bucket" "data_exports_bucket" {
  bucket = "cloud-cost-optimizer-data-exports"

  force_destroy = true
}

resource "aws_s3_bucket_versioning" "data_exports_bucket_versioning" {
  bucket = aws_s3_bucket.data_exports_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "data_exports_bucket_lifecycle" {
  bucket = aws_s3_bucket.data_exports_bucket.id

  rule {
    id     = "data-exports-bucket-lifecycle-rule"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}

# S3 bucket policy to allow Data Exports service to write
resource "aws_s3_bucket_policy" "data_exports" {
  depends_on = [aws_s3_bucket_policy.data_exports]

  bucket = aws_s3_bucket.data_exports_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDataExportsToWriteToBucket"
        Effect = "Allow"
        Principal = {
          Service = "bcm-data-exports.amazonaws.com"
        }
        Action = [
          "s3:PutObject",
        ]
        Resource = [
          "${aws_s3_bucket.data_exports_bucket.arn}",
          "${aws_s3_bucket.data_exports_bucket.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          StringLike = {
            "aws:SourceArn" = "arn:aws:bcm-data-exports:*:${data.aws_caller_identity.current.account_id}:export/*"
          }
        }
      }
    ]
  })
}


# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get current AWS partition
data "aws_partition" "current" {}

resource "aws_bcmdataexports_export" "data_exports" {
  export {
    name = "cost_optimizer_data_exports"
    data_query {
      query_statement = "SELECT bill_bill_type, bill_billing_entity, bill_billing_period_end_date, bill_billing_period_start_date, bill_invoice_id, bill_invoicing_entity, bill_payer_account_id, bill_payer_account_name, cost_category, discount, discount_bundled_discount, discount_total_discount, identity_line_item_id, identity_time_interval, line_item_availability_zone, line_item_blended_cost, line_item_blended_rate, line_item_currency_code, line_item_legal_entity, line_item_line_item_description, line_item_line_item_type, line_item_net_unblended_cost, line_item_net_unblended_rate, line_item_normalization_factor, line_item_normalized_usage_amount, line_item_operation, line_item_product_code, line_item_tax_type, line_item_unblended_cost, line_item_unblended_rate, line_item_usage_account_id, line_item_usage_account_name, line_item_usage_amount, line_item_usage_end_date, line_item_usage_start_date, line_item_usage_type, pricing_currency, pricing_lease_contract_length, pricing_offering_class, pricing_public_on_demand_cost, pricing_public_on_demand_rate, pricing_purchase_option, pricing_rate_code, pricing_rate_id, pricing_term, pricing_unit, product, product_comment, product_fee_code, product_fee_description, product_from_location, product_from_location_type, product_from_region_code, product_instance_family, product_instance_type, product_instancesku, product_location, product_location_type, product_operation, product_pricing_unit, product_product_family, product_region_code, product_servicecode, product_sku, product_to_location, product_to_location_type, product_to_region_code, product_usagetype, reservation_amortized_upfront_cost_for_usage, reservation_amortized_upfront_fee_for_billing_period, reservation_availability_zone, reservation_effective_cost, reservation_end_time, reservation_modification_status, reservation_net_amortized_upfront_cost_for_usage, reservation_net_amortized_upfront_fee_for_billing_period, reservation_net_effective_cost, reservation_net_recurring_fee_for_usage, reservation_net_unused_amortized_upfront_fee_for_billing_period, reservation_net_unused_recurring_fee, reservation_net_upfront_value, reservation_normalized_units_per_reservation, reservation_number_of_reservations, reservation_recurring_fee_for_usage, reservation_reservation_a_r_n, reservation_start_time, reservation_subscription_id, reservation_total_reserved_normalized_units, reservation_total_reserved_units, reservation_units_per_reservation, reservation_unused_amortized_upfront_fee_for_billing_period, reservation_unused_normalized_unit_quantity, reservation_unused_quantity, reservation_unused_recurring_fee, reservation_upfront_value, resource_tags, savings_plan_amortized_upfront_commitment_for_billing_period, savings_plan_end_time, savings_plan_instance_type_family, savings_plan_net_amortized_upfront_commitment_for_billing_period, savings_plan_net_recurring_commitment_for_billing_period, savings_plan_net_savings_plan_effective_cost, savings_plan_offering_type, savings_plan_payment_option, savings_plan_purchase_term, savings_plan_recurring_commitment_for_billing_period, savings_plan_region, savings_plan_savings_plan_a_r_n, savings_plan_savings_plan_effective_cost, savings_plan_savings_plan_rate, savings_plan_start_time, savings_plan_total_commitment_to_date, savings_plan_used_commitment FROM COST_AND_USAGE_REPORT"
      table_configurations = {
        COST_AND_USAGE_REPORT = {
          BILLING_VIEW_ARN                      = "arn:${data.aws_partition.current.partition}:billing::${data.aws_caller_identity.current.account_id}:billingview/primary"
          TIME_GRANULARITY                      = "HOURLY",
          INCLUDE_RESOURCES                     = "TRUE",
          INCLUDE_MANUAL_DISCOUNT_COMPATIBILITY = "FALSE",
          INCLUDE_SPLIT_COST_ALLOCATION_DATA    = "TRUE",
        }
      }
    }
    destination_configurations {
      s3_destination {
        s3_bucket = aws_s3_bucket.data_exports_bucket.bucket
        s3_prefix = aws_s3_bucket.data_exports_bucket.bucket_prefix
        s3_region = aws_s3_bucket.data_exports_bucket.region
        s3_output_configurations {
          overwrite   = "OVERWRITE_REPORT"
          format      = "TEXT_OR_CSV"
          compression = "GZIP"
          output_type = "CUSTOM"
        }
      }
    }

    refresh_cadence {
      frequency = "SYNCHRONOUS"
    }
  }
}

# Athena DB for AWS Data Exports
resource "aws_athena_database" "data_exports_db" {
  name   = "cloud_cost_optimizer_data_exports_db"
  bucket = aws_s3_bucket.data_exports_bucket.bucket
}