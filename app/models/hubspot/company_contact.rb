  module Hubspot
  #
  # HubSpot CONTACT OBJECT
  #
  class CompanyContact
    CONTACT_PATH='https://api.hubapi.com/crm/v3/objects/contacts'
    COMPANY_PATH='https://api.hubapi.com/crm/v3/objects/companies'

    def self.create_update_company_contact(contact,hs_company_id)
    	if contact.present?
    		contact.each do |f|
    			existing_user = Hubspot::Contact.find_contact_user(f["ID"])
          contact_profile = Simpro::Contact.get_contact(f["ID"])
          if existing_user["results"].blank?
            existing_user = Hubspot::Contact.find_by_email(contact_profile["Email"])
          end
          body_json = {
            "properties": {
              "salutation": contact_profile["Title"], 
               "phone": contact_profile["WorkPhone"].gsub(/[^0-9A-Za-z , : ]/, '') || '',
               "email": contact_profile["Email"],
               "alt_phone": contact_profile["AltPhone"].gsub(/[^0-9A-Za-z , : ]/, '') || '',
               "mobilephone": contact_profile["CellPhone"] || '',
               "fax": contact_profile["Fax"] || "",
               "position__c": contact_profile["Position"],
               "department": contact_profile["Department"],
               "firstname": contact_profile["GivenName"],
               "lastname": contact_profile["FamilyName"],
               "simpro_contact_id": contact_profile["ID"],
            }
          }
    			if existing_user["results"].blank?
    				 
            response = HTTParty.post("#{CONTACT_PATH}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
          else
            contact_id = existing_user["results"].first["id"]
            response = HTTParty.patch("#{CONTACT_PATH}/#{contact_id}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
          end  
          if response.present? && response.success?
          	Hubspot::CompanyContact.associate_contact_with_company(hs_company_id,response["id"])
          end
          if response.present? && response.success? && contact_profile["Sites"].present?
            Hubspot::Site.associate_sites_customer(contact_profile["Sites"],'individual',response["id"])
          end
    		end
    	end
    end

    def self.associate_contact_with_company(as_company_id,as_contact_id)
     	body_json = 	[
					  {
					   "associationCategory": "USER_DEFINED",
					   "associationTypeId": "#{ENV['CONTACT_ASSOCIATION_ID']}"
					  }
    		]
        response = HTTParty.put("https://api.hubapi.com/crm/v4/objects/contact/#{as_contact_id.to_i}/associations/company/#{as_company_id.to_i}",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })

    end
  end
end