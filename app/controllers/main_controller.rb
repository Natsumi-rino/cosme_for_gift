class MainController < ApplicationController
  def index
    month = Date.today.strftime("%m").to_i.to_s
    next_month = (month.to_i+1).to_s
    birthmonth = "( " + month + "・" + next_month + " 月 )"
    
    en2ja = { "birthday" => "誕生日#{birthmonth}",
              "coming_of_age" => "成人の日",
              "valentine" => "バレンタインデー",
              "white" => "ホワイトデー",
              "graduation" => "卒業式・追いコン",
              "entrance" => "入学式",
              "childrens" => "こどもの日",
              "mothers" => "母の日",
              "fathers" => "父の日",
              "thanksgiving" => "敬老感謝の日",
              "halloween" => "ハロウィン",
              "christmas" => "クリスマス"}
    if params[:event_name]==nil then
      @event_name_en = date2event(Date.today.strftime("%m%d"))
      @event_name_ja = en2ja[date2event(Date.today.strftime("%m%d"))]
    else
      @event_name_en = params[:event_name]
      @event_name_ja = en2ja[params[:event_name]]
    end
  end

  def gift_new
    event_name = params[:event_name]
    raw_hashes = []
    for month in month_from_event_name(event_name)
      year = month_to_year(month)
      filename = "#{Rails.root}/lib/new_release/new_release_#{year}_#{month}.json"
      raw_hashes.push(get_json(filename))
    end
    
    result = convert_with_price(raw_hashes)
    @petitprice, @lowprice, @middleprice, @highprice = *result
    
    month = Date.today.strftime("%m").to_i.to_s
    next_month = (month.to_i+1).to_s
    birthmonth = "( " + month + "・" + next_month + " 月 )"
    
    en2ja = { "birthday" => "誕生日#{birthmonth}",
              "coming_of_age" => "成人の日",
              "valentine" => "バレンタインデー",
              "white" => "ホワイトデー",
              "graduation" => "卒業式・追いコン",
              "entrance" => "入学式",
              "childrens" => "こどもの日",
              "mothers" => "母の日",
              "fathers" => "父の日",
              "thanksgiving" => "敬老感謝の日",
              "halloween" => "ハロウィン",
              "christmas" => "クリスマス"}
    if params[:event_name]==nil then
      @event_name_en = date2event(Date.today.strftime("%m%d"))
      @event_name_ja = en2ja[date2event(Date.today.strftime("%m%d"))]
    else
      @event_name_en = params[:event_name]
      @event_name_ja = en2ja[params[:event_name]]
    end
  end

  def gift_rank
    params = URI.encode_www_form({
      count: 50,
      client_id: '8f58b3318661f361f8e9b132ac356867d25ff005b4205b20eb1ce7f191cc0ccd'
    })
    uri = URI.parse("https://pf-api.cosme.net/cosme/v2/ranking/products?#{params}")
    raw_hash = exec_api(uri)
    @ranking = convert_with_rank(raw_hash)
  end

  def gift_recommend
  end

  def gift_event
  end

  def gift_month
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

def get_json(filename)
  begin
    raw_hash = File.open(filename) do |json_file|
      JSON.load(json_file)
    end
  rescue => error
    filename = "#{Rails.root}/lib/new_release/sample.json"
    raw_hash = File.open(filename) do |json_file|
      JSON.load(json_file)
    end
  end
  return raw_hash
end

def convert_with_price(raw_hashes)
  group_by_price_range = [{}, {}, {}, {}]
  for raw_hash in raw_hashes
    for res_hash in raw_hash["results"]
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
          if product["image_url"].nil?
            product["image_url"] = "https://lh3.googleusercontent.com/proxy/q9K-584jea7P1JJu_HKizXAOZRuGvhq3hqpTF_mMamAgF9vr8NBtWUgLeGnHUx0yPjZnR3sI26QeTbWfUlDynP6Y3oayozuRRdqKFY8"
          end
          prod = {
            "item_name" => product["product_name"],
            "price" => price,
            "image_url" => product["image_url"],
            "release_at" => Date.strptime(release_at,'%Y-%m-%d'),
            "shopping_link" => product["shopping_link"]
          }
          group_by_price_range[rate_index(price.to_i)][brand_name].push(prod)
        end
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

def convert_with_rank(raw_hash)
  converted_rank = []
  for rank in raw_hash["result"]
    item = {
        'rank'=> rank['rank'],
        'item_name'=> rank['product_name'],
        'brand_name'=> rank['brand_name'],
        'volume_price_label'=> rank['volume_price_label'],
        'image_url'=> rank['image_url'],
        'shopping_link'=> rank['shopping_link']
    }
    converted_rank.append(item)
  end
  return converted_rank
end

# date:String (example: date = "0125")
def date2event(date)
  if date <= "0115" then
    return "coming_of_age"
  elsif date <= "0214" then
    return "valentine"
  elsif date <= "0314" then
    return "white"
  elsif date <= "0331" then
    return "graduation"
  elsif date <= "0415" then
    return "entrance"
  elsif date <= "0505" then
    return "childrens"
  elsif date <= "0515" then
    return "mothers"
  elsif date <= "0615" then
    return "fathers"
  elsif date <= "0921" then
    return "thanksgiving"
  elsif date <= "1031" then
    return "halloween"
  elsif date <= "1225" then
    return "christmas"
  elsif date <= "1231" then
    return "coming_of_age"
  else
    return false
  end
end

def month_from_event_name(event)
  if event == "coming_of_age" then
    return [12,1]
  elsif event == "valentine" then
    return [1,2]
  elsif event == "white" then
    return [2,3]
  elsif event == "graduation" then
    return [2,3]
  elsif event == "entrance" then
    return [3,4]
  elsif event == "childrens" then
    return [4,5]
  elsif event == "mothers" then
    return [4,5]
  elsif event == "fathers" then
    return [5,6]
  elsif event == "thanksgiving" then
    return [8,9]
  elsif event == "halloween" then
    return [9,10]
  elsif event == "christmas" then
    return [11,12]
  elsif event == "birthday" then
    month = Date.today.month
    return [month,month+1]
  end
end


def month_to_year(month)
  today = Date.today
  if today.month+1 < month
    return today.year - 1
  end
  return today.year
end
