require 'httparty'
require 'json'

namespace :hubspot do
  desc "Create HubSpot custom object, group, and properties"
  task create_cost_center: :environment do
    class HubSpot
      include HTTParty
      base_uri 'https://api.hubapi.com'

      def initialize(access_token)
        @headers = {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        }
      end

      def create_custom_object
        endpoint = "/crm/v3/schemas"
        body = {
          name: "cost_centers",
          labels: {
            singular: "Cost Center",
            plural: "Cost Centers"
          },
          primaryDisplayProperty: "name",
          requiredProperties: [],
          metaType: "PORTAL_SPECIFIC"
        }

        response = self.class.post(endpoint, headers: @headers, body: body.to_json)
        puts "Custom Object Response: #{response.body}"
      end

      def create_group
        endpoint = "/crm/v3/properties/cost_centers/groups"
        body = {
          name: "cost_center_information",
          label: "Cost Center Information",
          displayOrder: 0
        }

        response = self.class.post(endpoint, headers: @headers, body: body.to_json)
        puts "Group Creation Response: #{response.body}"
      end

      def create_property(property_name, label)
        endpoint = "/crm/v3/properties/cost_centers"
        body = {
          name: property_name,
          label: label,
          type: "string",
          fieldType: "text",
          groupName: "cost_center_information"
        }

        response = self.class.post(endpoint, headers: @headers, body: body.to_json)
        puts "Property Creation Response (#{property_name}): #{response.body}"
      end
    end

    hubspot = HubSpot.new("#{ENV['HUBSPOT_API_KEY']}")

    # Step 1: Create Custom Object
    hubspot.create_custom_object

    # Step 2: Create Group
    hubspot.create_group

    # Step 3: Add Properties
    hubspot.create_property("name", "Name")
    hubspot.create_property("simpro_id", "Simpro ID")
  end
end
