class Metafield < ApplicationRecord
    validate :forbid_changing_key, on: :update
 
    validates :key, presence: true, length: {minimum: 3}
    validates :namespace, presence: true, length: {minimum: 3}
    validates :value, presence: true
    validates_uniqueness_of :key
 
    def self.import(file, product_ids)
         items = []
         CSV.foreach(file.path, headers: true) do |row|
             items << row.to_h   
         end
         arr = items[0]
         headers = arr.keys
         headers = headers.collect { |e| e.strip.downcase }
         if (headers.include? "key") && (headers.include? "namespace") && (headers.include? "value") 
             status = create_metafields(items, product_ids)
             return status
         else
             return 406
         end
     end
 
     def self.create_metafields(items, product_ids)
         i = 0
         while i < product_ids.count
             j = 0
             while j < items.count
                 metafield_details = items[j].map { |k, v| [k.strip.downcase, v] }.to_h
                 all_metafields = HTTParty.get("https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_API_SECRET']}@#{ENV['SHOPIFY_STORE_DOMAIN']}/admin/api/2021-01/products/#{product_ids[i]}/metafields.json")
                 if all_metafields["metafields"].any? { |hash| hash['key'] == metafield_details["key"] } == true
                     j = j + 1
                     next
                 elsif metafield_details["namespace"].nil? || metafield_details["value"].nil? || metafield_details["key"].nil?
                     return 400
                 elsif metafield_details["key"].size < 3 || metafield_details["namespace"].size < 3
                    return 422
                 else
                     Metafield.create(
                         key: metafield_details["key"],
                         namespace: metafield_details["namespace"],
                         value: metafield_details["value"]
                         )
                     response = HTTParty.post("https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_API_SECRET']}@#{ENV['SHOPIFY_STORE_DOMAIN']}/admin/api/2021-01/products/#{product_ids[i]}/metafields.json", 
                     :body => {
                         "metafield": {
                         "namespace": metafield_details["namespace"],
                         "key": metafield_details["key"],
                         "value": metafield_details["value"],
                         "value_type": "string"
                     }
                     }.to_json, :headers => { 'Content-Type' => 'application/json' })
                 end
                 j = j + 1
             end
            i = i + 1
          end
        return 300
     end
 
     private
 
     def forbid_changing_key
         errors.add :key, "can not be changed!" if self.key_changed?
         errors.add :namespace, "can not be changed!" if self.namespace_changed?
     end
 end