require 'httparty'
require 'json'

namespace :hubspot do
  desc "Create HubSpot custom object 'Site', group, and properties"
  task create_site_object: :environment do
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
          name: "sites",
          labels: {
            singular: "Site",
            plural: "Sites"
          },
          primaryDisplayProperty: "site_name", # Changed to 'site_name' for the display property
          requiredProperties: [],
          metaType: "PORTAL_SPECIFIC"
        }

        response = self.class.post(endpoint, headers: @headers, body: body.to_json)
        puts "Custom Object Response: #{response.body}"
      end

      # Step 2: Create Group
      def create_group
        endpoint = "/crm/v3/properties/sites/groups"
        body = {
          name: "site_information",
          label: "Site Information",
          displayOrder: 0
        }

        response = self.class.post(endpoint, headers: @headers, body: body.to_json)
        puts "Group Creation Response: #{response.body}"
      end

      # Step 3: Add Properties
      def create_property(property_name, label)
        endpoint = "/crm/v3/properties/sites"
        body = {
          name: property_name,
          label: label,
          type: "string",
          fieldType: "text",
          groupName: "site_information"
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
    properties = {
      "site_name" => "Site Name",
      "country" => "Country",
      "postal_address" => "Postal Address",
      "postal_postcode" => "Postal Postcode",
      "postal_state" => "Postal State",
      "postal_suburb" => "Postal Suburb",
      "site_primary_contact_first_name" => "Primary Contact First Name",
      "site_primary_contact_last_name" => "Primary Contact Last Name"
    }

    properties.each do |property_name, label|
      hubspot.create_property(property_name, label)
    end
  end
end
