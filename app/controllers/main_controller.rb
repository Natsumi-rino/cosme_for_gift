class MainController < ApplicationController
  def index
  end

  def gift
    year = Date.today.year
    month = Date.today.month  #  TODO: 次イベントの判定ロジックが実装され次第それに換装
    params = URI.encode_www_form({client_id: '8f58b3318661f361f8e9b132ac356867d25ff005b4205b20eb1ce7f191cc0ccd'})
    uri = URI.parse("https://pf-api.cosme.net/cosme/v3/product_releases/#{year}/#{month}?#{params}")
    raw_hash = exec_api(uri)
    result = convert_with_price(raw_hash["results"])
    @petitprice, @lowprice, @middleprice, @highprice = *result
  end
end

def exec_api(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    res = http.request(request)
    raw_hash = JSON.parse(res.body)
    return raw_hash
end

def convert_with_price(raw_hash)
  group_by_price_range = [{}, {}, {}, {}]
  for res_hash in raw_hash
    release_at, brands = res_hash["date"], res_hash["brands"]
    for brand in brands
      brand_name = brand["brand_name"]
      for group in group_by_price_range
        group[brand_name] = [] if !group.has_key?(brand_name)
      end
      for product in brand["products"]
        if product["sku"]["volume_sales"].length.zero?
          next
        end
        price = product["sku"]["volume_sales"][0]["sales"]["price_value_from"]
        prod = {
          "name" => product["product_name"],
          "price" => price,
          "image-url" => product["image_url"],
          "release-at" => Date.strptime(release_at,'%Y-%m-%d'),
          "shopping-link" => product["shopping_link"]
        }
        group_by_price_range[rate_index(price.to_i)][brand_name].push(prod)
      end
    end
  end
  group_by_price_range.each_with_index{|group, index|
    new_group = []
    group.each{|brand_name, products|
      if products.length.zero?
        next
      end
      new_group.push({"brand_name"=>brand_name, "products" => products})
    }
    group_by_price_range[index] = new_group
  }
  return group_by_price_range
end

def rate_index(price)
  if price < 2000 then
    return 0
  elsif price < 5000
    return 1
  elsif price < 10000
    return 2
  else
    return 3
  end
end
