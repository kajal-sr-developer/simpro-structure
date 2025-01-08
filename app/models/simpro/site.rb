module Simpro
  # Simpro company OBJECT
  class Site
  	def self.create_find_site(site_detail)
      site = site_detail["properties"]
  		simpro_site = Simpro::Site.get_site(site["site_name"]["value"])
      site_name = site["site_name"]["value"] rescue "--"
      site_id = site["hs_object_id"]["value"]
      address = site["street_address"].present? && site["street_address"]["value"].present? ? site["street_address"]["value"] : nil
      city = site["suburb"].present? && site["suburb"]["value"].present? ? site["suburb"]["value"] : nil
      state = site["state"].present? && site["state"]["value"].present? ? site["state"]["value"] : nil
      zip = site["post_code"].present? && site["post_code"]["value"].present? ? site["post_code"]["value"] : nil
      country = site["country"].present? && site["country"]["value"].present? ? site["country"]["value"] : nil
      postal_address = site["postal_address"].present? && site["postal_address"]["value"].present? ? site["postal_address"]["value"] : nil
      postal_city = site["postal_suburb"].present? && site["postal_suburb"]["value"].present? ? site["postal_suburb"]["value"] : nil
      postal_state = site["postal_state"].present? && site["postal_state"]["value"].present? ? site["postal_state"]["value"] : nil
      postal_zip = site["postal_postcode"].present? && site["postal_postcode"]["value"].present? ? site["postal_postcode"]["value"] : nil
      body_json = {
      "Name": site_name,
      "Address": {
         "Address": address,
         "City": city,
         "State": state,
         "PostalCode": zip,
         "Country": country,
        },"BillingAddress": {
         "Address": postal_address,
         "City": postal_city,
         "State": postal_state,
         "PostalCode": postal_zip,
        }
      }
      if simpro_site.present?
      	site_id = simpro_site.first["ID"]
      	response = HTTParty.patch("#{ENV['SIMPRO_LIVE_URL']}/sites/#{site_id}",:body=> body_json.to_json, :headers => {
        "Content-Type" => "application/json",
         "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
        })
      else
        response = HTTParty.post("#{ENV['SIMPRO_LIVE_URL']}/sites/",:body=> body_json.to_json, :headers => {
        "Content-Type" => "application/json",
         "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
        }) 
        if response.present? && response.success?
           Hubspot::Site.update_simpro_id(response["ID"],site_id)
        end 
      end
    end

    def self.create_update_site_webhook(site_id)
      query = { 
        "columns"     => "ID,Name,Address,BillingAddress,BillingContact,PrimaryContact,PublicNotes,Zone,Customers,CustomFields",
        "pageSize"      => 1
       }

      response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/sites/#{site_id}",:query=> query, :headers => {
        "Content-Type" => "application/json",
         "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
      })
      if response.present?
          Hubspot::Site.create_site(response)
      else 
        puts "end the loop"
      end
    end

    def self.create_deal_site(site_name,site_address)
       body_json = {
      "Name": site_name,
      "Address": {
         "Address": site_address
        }
      }
      response = HTTParty.post("#{ENV['SIMPRO_LIVE_URL']}/sites/",:body=> body_json.to_json, :headers => {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
      })
    end

    def self.get_site(site_name)
      query = { 
           "columns"     => "ID,Name",
           "search" => "any"
         }
      site_name = CGI.escape(site_name)
      response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/sites/?Name=#{site_name}",:query=> query, :headers => {
        "Content-Type" => "application/json",
         "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
      })
    end



    # def self.sync_product
    #   for i in 408..700
    #     query = { 
    #       "columns"     => "ID,Name,PartNo,UPC,Manufacturer,CountryOfOrigin,UOM,TradePrice,TradePriceEx,SplitPrice,SellPrice,EstimatedTime,TradeSplitQty,MinPackQty,PurchasingStage,IsFavorite,IsInventory,PurchaseTaxCode,SalesTaxCode,Group,SearchTerm,Notes,Archived",
    #       "pageSize"      => 50,
    #        "page" => i
    #      }

    #     response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/catalogs/?display=all",:query=> query, :headers => {
    #       "Content-Type" => "application/json",
    #        "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
    #     })
    #     if response.present?
    #       response.each do |response_data|
    #         Hubspot::Product.create_product(response_data)
    #       end
    #     else
    #        puts "end the loop"
    #     end
    #      puts "-----------------#{i}----------------------------"
    # end
    # end


    # def self.sync_site
    #  for i in 1..111
    #   query = { 
    #     "columns"     => "ID,Name,Address,BillingAddress,BillingContact,PrimaryContact,PublicNotes,Zone,Customers,CustomFields",
    #     "pageSize"      => 50,
    #      "page" => i
    #    }

    #   response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/sites/?display=all",:query=> query, :headers => {
    #       "Content-Type" => "application/json",
    #        "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
    #     })


    #     if response.present?
    #       response.each do |response_data|
           
    #         Hubspot::Site.create_site(response_data)
    #       end
    #     else 
    #       puts "end the loop"
    #     end

    #     puts "-----------------#{i}----------------------------"
    #   end
    # end
  end
end