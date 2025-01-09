require 'httparty'
require 'json'

namespace :hubspot do
  desc "Create HubSpot custom object 'Job', group, and properties"
  task create_job_object: :environment do
    class HubSpot
      include HTTParty
      base_uri 'https://api.hubapi.com'

      def initialize(access_token)
        @headers = {
        "Authorization" => "Bearer #{access_token}",
        "Content-Type" => "application/json"
      }
    end

    # Step 1: Create Custom Object
    def create_custom_object
      endpoint = "/crm/v3/schemas"
      body = {
        name: "jobs",
        labels: {
          singular: "Job",
          plural: "Jobs"
        },
        primaryDisplayProperty: "name",  # Displaying the name as primary display property
        requiredProperties: [],
        metaType: "PORTAL_SPECIFIC"
      }

      response = self.class.post(endpoint, headers: @headers, body: body.to_json)
      puts "Custom Object Response: #{response.body}"
    end

    # Step 2: Create Group
    def create_group(group_name, group_label)
      endpoint = "/crm/v3/properties/jobs/groups"
      body = {
        name: group_name,
        label: group_label,
        displayOrder: 0
      }

      response = self.class.post(endpoint, headers: @headers, body: body.to_json)
      puts "Group Creation Response: #{response.body}"
    end

    # Step 3: Add Properties
    def create_property(property_name, label, group_name, field_type, type = "string")
      endpoint = "/crm/v3/properties/jobs"
      body = {
        name: property_name,
        label: label,
        type: type,
        fieldType: field_type,
        groupName: group_name
      }

      response = self.class.post(endpoint, headers: @headers, body: body.to_json)
      puts "Property Creation Response (#{property_name}): #{response.body}"
    end
  end

  hubspot = HubSpot.new("#{ENV['HUBSPOT_API_KEY']}")

  # Step 1: Create Custom Object
  hubspot.create_custom_object

  # Step 2: Create Groups for Job Information, Resources Cost, etc.
  hubspot.create_group("job_information", "Job Information")
  hubspot.create_group("resources_cost", "Resources Cost")
  hubspot.create_group("gross_margin", "Gross Margin")
  hubspot.create_group("materials_cost", "MaterialsCost")
  hubspot.create_group("sync_info", "Sync Info")

  # Step 3: Add Properties under respective groups with correct field types
  properties = {
    # Job Information
    "name" => { label: "Job Name", field_type: "text" },
    "site_name" => { label: "Site Name", field_type: "text" },
    "job_id" => { label: "Job Id", field_type: "text" },
    "job_link" => { label: "Job Link", field_type: "text" },
    "quote_link" => { label: "Quote Link", field_type: "text" },
    "job_type" => { label: "Job Type", field_type: "select", type: "enumeration" },
    "scheduled_date" => { label: "Scheduled Date", field_type: "date" },
    "expiry_date" => { label: "Expiry Date", field_type: "date" },
    "created_date" => { label: "Created Date", field_type: "date" },
    "due_date" => { label: "Due Date", field_type: "date" },
    "discount" => { label: "Discount", field_type: "text" },
    "invoiced_value" => { label: "Invoiced Value", field_type: "number", type: "double" },
    "invoiced_percentage" => { label: "Invoiced Percentage", field_type: "number", type: "double" },
    "hydraulic_services_total" => { label: "Hydraulic Services Total (Ex GST)", field_type: "rollup" },
    "jwc_solids_handling_total" => { label: "JWC Solids Handling Total (Ex GST)", field_type: "rollup" },
    "mechanical_services_total" => { label: "Mechanical Services Total (Ex GST)", field_type: "rollup" },
    "sync_notes" => { label: "Sync Notes", field_type: "textarea" },
    "sync_time" => { label: "Sync Time", field_type: "text" },
    "simpro_job_status" => { label: "Simpro Job Status", field_type: "text" },
    "total_value" => { label: "Total Value (Ex GST)", field_type: "rollup" },

    # Resources Cost
    "estimated_plant_and_equipment_hours" => { label: "Estimated Plant And Equipment Hours", field_type: "number", type: "double" },
    "revised_plant_and_equipment" => { label: "Revised Plant And Equipment", field_type: "number", type: "double" },
    "actual_commission" => { label: "Actual Commission", field_type: "number", type: "double" },
    "actual_gross_margin" => { label: "Actual Gross Margin", field_type: "number", type: "double" },
    "actual_gross_profit" => { label: "Actual Gross Profit", field_type: "number", type: "double" },
    "actual_labour" => { label: "Actual Labour", field_type: "number", type: "double" },
    "actual_labour_hours" => { label: "Actual Labour Hours", field_type: "number", type: "double" },
    "actual_material_cost" => { label: "Actual Material Cost", field_type: "number", type: "double" },
    "actual_materials_markup" => { label: "Actual Materials Markup", field_type: "number", type: "double" },
    "actual_net_profit" => { label: "Actual Net Profit", field_type: "number", type: "double" },
    "actual_nett_margin" => { label: "Actual Nett Margin", field_type: "number", type: "double" },
    "actual_overhead" => { label: "Actual Overhead", field_type: "number", type: "double" },
    "actual_plant_and_equipment" => { label: "Actual Plant And Equipment", field_type: "number", type: "double" },
    "actual_resource_cost" => { label: "Actual Resource Cost", field_type: "number", type: "double" },
    "actual_resource_markup" => { label: "Actual Resource Markup", field_type: "number", type: "double" },

    # Estimated Costs
    "estimated_resource_cost" => { label: "Estimated Resource Cost", field_type: "number", type: "double" },
    "estimated_resource_markup" => { label: "Estimated Resource Markup", field_type: "number", type: "double" },

    # Sync Info
    "initial_sync" => { label: "Initial Sync", field_type: "datetime" },
    "last_synced" => { label: "Last Synced", field_type: "datetime" },
  }

  properties.each do |property_name, details|
    hubspot.create_property(property_name, details[:label], "job_information", details[:field_type], details[:type] || "string")
  end
end
end
