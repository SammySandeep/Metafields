class MetafieldsController < ApplicationController
    before_action :set_metafield, only: %i[ show edit update destroy ]
  
    def index
      @metafields = Metafield.all
    end
  
    def new
      @metafield = Metafield.new
    end
  
    def edit
    end
  
    def create
      i = 0
      @product_id = find_all_product_ids
      @metafield = Metafield.new(metafield_params)
      while i < @product_id.count
        all_metafields = HTTParty.get("https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_API_SECRET']}@#{ENV['SHOPIFY_STORE_DOMAIN']}/admin/api/2021-01/products/#{@product_id[i]}/metafields.json")
            if all_metafields["metafields"].any? { |hash| hash['key'] == @metafield.key } == true
              i = i + 1
              next
            else
              HTTParty.post("https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_API_SECRET']}@#{ENV['SHOPIFY_STORE_DOMAIN']}/admin/api/2021-01/products/#{@product_id[i]}/metafields.json", 
              :body => {
                "metafield": {
                  "namespace": @metafield.namespace,
                  "key": @metafield.key,
                  "value": @metafield.value,
                  "value_type": "string"
                }
              }.to_json, :headers => { 'Content-Type' => 'application/json' })
            end
          i = i + 1
      end
      respond_to do |format|
        if @metafield.save
        format.html { redirect_to metafields_path, notice: "Metafield was successfully created for all products." }
        format.json { render :index, status: :ok, location: @metafield }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @metafield.errors, status: :unprocessable_entity }
        end
      end
    end
  
    def import 
      file = params[:file]
      if file.nil?
        redirect_to metafields_path, notice: "CSV document not present."
      else
        status = Metafield.import(file, find_all_product_ids)
        if status == 406
            redirect_to metafields_path, notice: "Missing 'key', 'namespace or 'value' columns for the file!"
        elsif status == 400
            redirect_to metafields_path, notice: "Please fill all the columns in your csv document"
        elsif status == 422
            redirect_to metafields_path, notice: "Please check your csv document. Key and Namespace must contain a minimum of 3 characters"
        else
            redirect_to metafields_path, notice: "Metafield was successfully created for all products."
        end
      end   
    end
  
    def update
      i = 0
      @product_id = find_all_product_ids
      while i < @product_id.count
        all_metafields = HTTParty.get("https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_API_SECRET']}@#{ENV['SHOPIFY_STORE_DOMAIN']}/admin/api/2021-01/products/#{@product_id[i]}/metafields.json")
        if all_metafields["metafields"].any? { |hash| hash['key'] == @metafield.key } == true
          all_metafields["metafields"].each do |metafield|
            if metafield.has_value?(@metafield.key)
              if metafield["value"] != metafield_params[:value]
                HTTParty.put("https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_API_SECRET']}@#{ENV['SHOPIFY_STORE_DOMAIN']}/admin/api/2021-01/products/#{@product_id[i]}/metafields/#{metafield["id"]}.json", 
                :body => {
                  "metafield": {
                    "id": metafield["id"],
                    "value": metafield_params[:value],
                    "value_type": "string"
                  }
                }.to_json, :headers => { 'Content-Type' => 'application/json' })
              end
            end
          end
        end
        i = i + 1
      end
      respond_to do |format|
        if @metafield.update(metafield_params)
          format.html { redirect_to metafields_path, notice: "Metafield was successfully updated for all products." }
          format.json { render :index, status: :ok, location: @metafield }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @metafield.errors, status: :unprocessable_entity }
        end
      end
    end
  
    def destroy
      i = 0
      @product_id = find_all_product_ids
      while i < @product_id.count
        all_metafields = HTTParty.get("https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_API_SECRET']}@#{ENV['SHOPIFY_STORE_DOMAIN']}/admin/api/2021-01/products/#{@product_id[i]}/metafields.json")
        if all_metafields["metafields"].any? { |hash| hash['key'] == @metafield.key } == true
          all_metafields["metafields"].each do |metafield|
            if metafield.has_value?(@metafield.key)
              metafield.each do |key,value|
                if key == "id"
                  HTTParty.delete("https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_API_SECRET']}@#{ENV['SHOPIFY_STORE_DOMAIN']}/admin/api/2021-01/products/#{@product_id[i]}/metafields/#{value}.json")
                end
              end
            end
          end
        else
          i = i + 1
          next  
        end
        i = i + 1
      end
      @metafield.destroy
      respond_to do |format|
        format.html { redirect_to metafields_url, notice: "Metafield was successfully destroyed for all products." }
        format.json { head :no_content }
      end
    end
  
    private

  
    def find_all_product_ids
      product_id = Array.new
        all_products = HTTParty.get("https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_API_SECRET']}@#{ENV['SHOPIFY_STORE_DOMAIN']}/admin/api/2021-01/products.json?fields=id")
        all_products["products"].each do |product|
          product.each do |key,value|    
            if key == "id"    
              product_id << value      
            end 
          end  
        end  
      return product_id
    end
  
      def set_metafield
        @metafield = Metafield.find(params[:id])
      end
  
      def metafield_params
        params.require(:metafield).permit(:key, :namespace, :value)
      end
  end