require "net/http"
require "uri"
require 'nokogiri'
class ParseDiam
  def initialize(id, carat = 0)
    @cert_number = id.to_s
    @carat = carat.to_f.round(2)
    @carat = @carat.to_s+"0" if @carat.to_s.size() < 4

    @cert_type = @cert_number[0,4]
    if @cert_type == "IGI-"
      @cert_number[4,1] =~ /[0-9]/ ? @cert_type = "IGIUS" : @cert_type = "IGIAS"
    end
    @cert_number = @cert_number.split('-')[1]
  end

  def answer
    @answer
  end

  def simple_get_meth(url)
    uri = URI(url)
    req = Net::HTTP.get(uri)
  end

  def simple_post_meth(url, params)
    uri = URI(url)
    req = Net::HTTP::Post.new(uri)
    req.set_form_data(params)
    req['user-agent'] = "Mozilla/5.0 (compatible; MSIE 5.01; Windows NT 5.0)"
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
    res.body
  end

  def get_some_info(result, symbol_start, ss_cnt_pos, symbol_end, step=50, some_key=0)
    return '' if (str_pos = result.index(symbol_start)) == nil
    #str_pos = result.index(symbol_start)
    result = result.slice(str_pos+ss_cnt_pos, step)
    str_end = result.index(symbol_end, some_key)
    info = result.slice(0, str_end)
  end

  def cleane_arr(arr, num, sepa, pos=1)
    str = arr[num].split("#{sepa}")[pos]
    str[0] = ''
    str[-1] = ''
    return str
  end

  def parse_response(resp, type, igi_cert_type = 2)
    # t.string  "shape" (also called "cut")
    # t.float   "carat"
    # t.string  "clarity"
    # t.string  "color"
    # t.string  "fancy_color"
    # t.string  "fancy_color_intensity"
    # t.string  "fancy_color_overtone"
    # t.string  "fluorescence_intensity"
    # t.string  "fluorescence_color"
    # t.string  "make"
    # t.string  "polish"
    # t.string  "symmetry"
    # t.float   "length"
    # t.float   "width"
    # t.float   "height"
    # t.float   "ratio"
    # t.float   "depth"
    # t.float   "table_size"
    # t.float   "crown_height"
    # t.float   "pavilion_depth"
    # t.string  "girdle"
    # t.string  "culet_size"
    # t.string  "culet_condition"
    # t.string  "graining"
    # t.text    "remarks" (also called "comments")
    # t.string  "certificate_path" (URL to the grading lab website)
    case type
      when "EGLI"
        res =  resp.css("table")[1].to_s

        #parse  fluorescence
        fluor_color = ''
        fluor_int = get_some_info(res, '<h6>Fluorescence:</h6>', 38, '</span>', 100)
        if fluor_int != 'None'
          fluor_arr = fluor_int.split
          if  fluor_arr.size == 3
            fluor_color  = fluor_arr[2].downcase.capitalize
            fluor_int  = fluor_arr[0].downcase.capitalize +' ' + fluor_arr[1].downcase.capitalize
          elsif fluor_arr.size == 2
            fluor_color  = fluor_arr[1].downcase.capitalize
            fluor_int  = fluor_arr[0].downcase.capitalize
          else
            fluor_int  = fluor_arr[0].downcase.capitalize
          end
        end

        #parse comment
        comment = ''
        comments =  Nokogiri::HTML(get_some_info(res, 'egl-results-title">Comments', 42, '</table>', 2000))
        if  comments.css("tr").length > 0
          i=0
          loop do
            comment << comments.css("tr")[i].css("td")[0].css("span").text + '|'
            i+=1
            break if i == comments.css("tr").length
          end
        end

        #parse leigth width height
        mess = get_some_info(res, 'Measurements:', 34, '</span>', 50)
        if mess.index('-')
          mess1 = mess.split(' - ')
          leigth_v = mess1[0]
          mess2 = mess1[1].split(' x ')
          width = mess2[0]
          height = mess2[1]
        else
          mess1 = mess.split(' x ')
          leigth_v = mess1[0]
          width = mess1[1]
          height = mess1[2]
        end

        answer = {'shape' => get_some_info(res, 'Shape and Cut:', 35, '</span>', 70),
                  'carat' => get_some_info(res, 'Carat Weight:', 34, '</span>', 70).to_f.round(2),
                  'clarity' => get_some_info(res, 'Clarity Grade:', 35, '</span>', 70),
                  'color' => get_some_info(res, 'Color Grade:', 34, '</span>', 70),
                  'fancy_color' => '',
                  'fancy_color_intensity' => '',
                  'fancy_color_overtone' => '',
                  'fluorescence_intensity' => fluor_int,
                  'fluorescence_color' => fluor_color,
                  'make' => '',
                  'polish' => get_some_info(res, 'Polish:', 28, '</span>', 70),
                  'symmetry' => get_some_info(res, 'Symmetry:', 30, '</span>', 70),
                  'length' => leigth_v.to_f, 'width' => width.to_f, 'height' => height.to_f,
                  'ratio' => '',
                  'depth' => get_some_info(res, 'Total Depth:', 34, '</span>', 70).split()[0].to_f,
                  'table_size' => get_some_info(res, 'Table Width:', 33, '</span>', 70).split()[0].to_f,
                  'crown_height' => get_some_info(res, 'Crown Height:', 34, '</span>', 70).split()[0].to_f,
                  'pavilion_depth' => get_some_info(res, 'Pavillon Depth:', 36, '</span>', 70).split()[0].to_f,
                  'girdle' => get_some_info(res, 'Girdle Thickness:', 38, '</span>', 70),
                  'culet_size' => '',
                  'culet_condition' => '',
                  'graining' => '',
                  'remarks' => comment,
                  'certificate_path' => 'http://www.eglinternational.org/egl/online-verification'}


      when "GIA-"
        mess = get_some_info(resp, '<LENGTH>', 8, '</LENGTH>', 100)
        if mess.index('-')
          mess1 = mess.split(' - ')
          leigth_v = mess1[0]
          mess2 = mess1[1].split(' x ')
          width = mess2[0]
          height = mess2[1]
        else
          mess1 = mess.split(' x ')
          leigth_v = mess1[0]
          width = mess1[1]
          height = mess1[2]
        end

        comments = get_some_info(resp, '<REPORT_COMMENTS>', 17, '</REPORT_COMMENTS>', 110)
        comments.slice!("LINEBREAK")
        comments.slice!("&#xd;")

        answer = {"shape"=>get_some_info(resp, '<SHAPE>', 7, '</SHAPE>', 100),
        "carat"=>get_some_info(resp, '<WEIGHT>', 8, '</WEIGHT>', 100).to_f.round(2),
        "clarity"=>get_some_info(resp, '<CLARITY>', 9, '</CLARITY>', 100),
        "color"=>get_some_info(resp, '<COLOR>', 7, '</COLOR>', 100),
        "fancy_color"=>'',
        "fancy_color_intensity"=>'',
        "fancy_color_overtone"=>'',
        "fluorescence_intensity"=>get_some_info(resp, '<FLUORESCENCE_INTENSITY>', 24, '</FLUORESCENCE_INTENSITY', 100).split()[0],
        "fluorescence_color"=>get_some_info(resp, '<FLUORESCENCE_COLOR>', 20, '</FLUORESCENCE_COLOR', 100),
        "make"=>'',
        "polish"=>get_some_info(resp, '<POLISH>', 8, '</POLISH>', 100),
        "symmetry"=>get_some_info(resp, '<SYMMETRY>', 10, '</SYMMETRY>', 100),
        "length"=>leigth_v.to_f, "width"=>width.to_f, "height"=>height.to_f,
        "ratio"=>'',
        "depth"=>get_some_info(resp, '<DEPTH_PCT>', 11, '</DEPTH_PCT>', 100).to_f,
        "table_size"=>get_some_info(resp, '<TABLE_PCT>', 11, '</TABLE_PCT>', 100).to_f,
        "crown_height"=>'',
        "pavilion_depth"=>get_some_info(resp, '<PAV_DP>', 8, '</PAV_DP>', 100).to_f,
        "girdle"=>get_some_info(resp, '<GIRDLE>', 8, '</GIRDLE>', 100).split()[0],
        "culet_size"=>get_some_info(resp, '<CULET_SIZE>', 12, '</CULET_SIZE>', 100),
        "culet_condition"=>get_some_info(resp, '<CULET_CODE>', 12, '</CULET_CODE>', 100).capitalize,
        "graining"=>'',
        "remarks"=> comments,
        "certificate_path"=> "http://www.gia.edu/cs/Satellite?reportno=#{@cert_number}&childpagename=GIA%2FPage%2FReportCheck&pagename=GIA%2FDispatcher&c=Page&cid=1355954554547"}

      when "IGIUS"
        def get_val_td(resp, value, p=1)
          elw = resp.search "[text()*='#{value}']"
          return '777' if elw.empty?
          case p
            when 3
              return '777' if elw.first.parent.parent.parent.next_element.nil? || elw.first.parent.parent.parent.next_element.css('font').text.empty?
              el = elw.first.parent.parent.parent.next_element.css('font').text
            when 2
              return '777' if elw.first.parent.parent.next_element.nil? || elw.first.parent.parent.next_element.css('font').text.empty?
              el = elw.first.parent.parent.next_element.css('font').text
            when 1
              return '777' if elw.first.parent.next_element.text.nil? || elw.first.parent.next_element.css('font').text.empty?
              el = elw.first.parent.next_element.css('font').text
            else
              return '777' if elw.first.parent.nil?
              el = elw.first.parent.text
          end
          return el.to_s
        end


        eee= resp.search "[text()*='FLUORESCENCE']"
        #return  eee.first.parent.next_element.css('font').text.class
        #parse leigth width height
        mess = get_val_td(resp, "Measurements")
        if mess.index('-')
          mess1 = mess.split(' - ')
          leigth_v = mess1[0]
          mess2 = mess1[1].split(' x ')
          width = mess2[0]
          height = mess2[1]
        else
          mess1 = mess.split(' x ')
          leigth_v = mess1[0]
          width = mess1[1]
          height = mess1[2]
        end

        #parse fluorescence
          fluorescence_color = ''
        if igi_cert_type == 2
          fluor = get_val_td(resp, "FLUORESCENCE",  1).split()
          if fluor.length>1
            fluorescence_intensity = fluor[0].downcase.capitalize
            fluorescence_color = fluor[1].downcase.capitalize
          else
            fluorescence_intensity = fluor[0].downcase.capitalize
          end
        else
          fluor = get_val_td(resp, "Fluorescence").split()
          if fluor.length>1
            fluorescence_intensity = fluor[0].downcase.capitalize
            fluorescence_color = fluor[1].downcase.capitalize
          else
            fluorescence_intensity = fluor[0].downcase.capitalize
          end
        end

        if igi_cert_type == 2
          answer = {'shape' => get_val_td(resp, "SHAPE AND CUT", 2).split()[0].downcase.capitalize,
                    'carat' =>  get_val_td(resp, "Weight :", 2).to_f,
                    'clarity' => get_val_td(resp, "CLARITY GRADE", 2).tr_s(' ',''),
                    'color' => get_val_td(resp, "COLOR", 2),
                    'fancy_color' => '',
                    'fancy_color_intensity' => '',
                    'fancy_color_overtone' => '',
                    'fluorescence_intensity' => fluorescence_intensity,
                    'fluorescence_color' => fluorescence_color,
                    'make' => '',
                    'polish' => get_val_td(resp, "Polish").downcase.capitalize,
                    'symmetry' => get_val_td(resp, "Symmetry").downcase.capitalize,
                    'length' => leigth_v.to_f, 'width' => width.to_f, 'height' => height.to_f,
                    'ratio' => '',
                    'depth' => get_val_td(resp, "Total Depth").to_f,
                    'table_size' =>get_val_td(resp, "Table Diameter").to_f,
                    'crown_height' => get_val_td(resp, "Crown Height").to_f,
                    'pavilion_depth' => get_val_td(resp, "Pavilion Depth").to_f,
                    'girdle' => get_val_td(resp, "Girdle Thickness").downcase.capitalize,
                    'culet_condition' => '',
                    'culet_size' => get_val_td(resp, "Culet Size").downcase.capitalize,
                    'graining' => '',
                    'remarks' => get_val_td(resp, "Comments", 0).gsub(/\r\n/, ''),
                    'certificate_path' => "http://igionline.com/igiweb/onlinereport/View_InstCert.cfm?pCert=#{@cert_number}&pWT=#{@carat}"}
        else
          answer = {'shape' => get_val_td(resp, "Shape and Cutting Style", 3).split()[0].downcase.capitalize,
                    'carat' =>  get_val_td(resp, "Weight :", 2).to_f,
                    'clarity' => get_val_td(resp, "Clarity Grade", 3).tr_s('\(\)',''),
                    'color' => get_val_td(resp, "Color Grade", 3).tr_s('\(\)',' ').split()[1],
                    'fancy_color' => '',
                    'fancy_color_intensity' => '',
                    'fancy_color_overtone' => '',
                    'fluorescence_intensity' => fluorescence_intensity.split('.')[0],
                    'fluorescence_color' => fluorescence_color,
                    'make' => '',
                    'polish' => get_val_td(resp, "Polish").capitalize.split('.')[0].capitalize,
                    'symmetry' => get_val_td(resp, "Symmetry").downcase.capitalize,
                    'length' => leigth_v.to_f, 'width' => width.to_f, 'height' => height.to_f,
                    'ratio' => '',
                    'depth' => '',
                    'table_size' =>'',
                    'crown_height' => '',
                    'pavilion_depth' => '',
                    'girdle' => '',
                    'culet_condition' => '',
                    'culet_size' => '',
                    'graining' => '',
                    'remarks' => get_val_td(resp, "Comments", 0).gsub(/\r\n/, ''),
                    'certificate_path' => "http://igionline.com/igiweb/onlinereport/View_Cert.cfm?pCert=#{@cert_number}"}
        end

      when "IGIAS"
        def get_val_td(resp, value)
          elw = resp.search "[text()*='#{value}']"
          return '777' if elw.empty? or elw.first.parent.next_element.nil?
          el = elw.first.parent.next_element.css('span').text
          return el.to_s
        end
        #parse leigth width height
        mess = get_val_td(resp, 'Measurements')
        if mess.index('-')
          mess1 = mess.split(' - ')
          leigth_v = mess1[0]
          mess2 = mess1[1].split(' x ')
          width = mess2[0]
          height = mess2[1]
        else
          mess1 = mess.split(' x ')
          leigth_v = mess1[0]
          width = mess1[1]
          height = mess1[2]
        end
        fluor = get_val_td(resp, "Fluorescence").split()
        if fluor.length>1
          fluorescence_intensity = fluor[0].downcase.capitalize
          fluorescence_color = fluor[1].downcase.capitalize
        else
          fluorescence_intensity = fluor[0].downcase.capitalize
          fluorescence_color = ''
        end
        crowns = get_val_td(resp, "Crown Height").split('-')
        if crowns.length>1
          crown_h = crowns[0]
          crown_a = crowns[1]
        else
          crown_h = crowns[0]
          crown_a = '777'
        end
        pavilions = get_val_td(resp, "Pavilion Depth").split('-')
        if pavilions.length>1
          pavilion_h = crowns[0]
          pavilion_a = crowns[1]
        else
          pavilion_h = crowns[0]
          pavilion_a = '777'
        end
        #parse clarity
        clarity = get_val_td(resp, 'Clarity Grade').split()
        if clarity.length>1
          clarity1 = clarity[0].capitalize
          clarity2 = clarity[1].capitalize
          clarity = clarity1 + " " + clarity2
        else
          clarity = clarity[0].capitalize
        end

        answer = {'shape' => get_val_td(resp, 'Shape And Cut').split()[0].downcase.capitalize,
                  'carat' => get_val_td(resp, 'Carat Weight').to_f.round(2),
                  'clarity' => clarity,
                  'color' => get_val_td(resp, 'Color Grade')[1,1],
                  'fancy_color' => '',
                  'fancy_color_intensity' => '',
                  'fancy_color_overtone' => '',
                  'fluorescence_intensity' => fluorescence_intensity,
                  'fluorescence_color' => fluorescence_color,
                  'make' => '',
                  'polish' => get_val_td(resp, 'Polish'),
                  'symmetry' => get_val_td(resp, 'Symmetry'),
                  'length' => leigth_v.to_f,'width' => width.to_f, 'height' => height.to_f,
                  'ratio' => '',
                  'depth' => '',
                  'table_size' => get_val_td(resp, 'Table').to_f,
                  'crown_height' => crown_h.to_f,
                  'crown_angle' => crown_a.to_f,
                  'pavilion_depth' => pavilion_h.to_f,
                  'pavilion_angle' => pavilion_a.to_f,
                  'girdle' => get_val_td(resp, 'Girdle Thickness').split()[0],
                  'culet_size' => '',
                  'culet_condition' => get_val_td(resp, 'Culet').split()[0],
                  'graining' => '',
                  'remarks' => '',
                  'certificate_path' => 'http://www.igiworldwide.com/search_report.aspx'}

      when "EGLU"
        arr_res = get_some_info(resp, "include_callback && include_callback", 37, ");", 500).split(",")
        #parse leigth width height
        mess =  cleane_arr(arr_res, 7, ":", 2)
        if mess.index('-')
          mess1 = mess.split(' - ')
          leigth_v = mess1[0]
          mess2 = mess1[1].split(' x ')
          width = mess2[0]
          height = mess2[1]
        else
          mess1 = mess.split(' x ')
          leigth_v = mess1[0]
          width = mess1[1]
          height = mess1[2]
        end
        polish = cleane_arr(arr_res, 16, ":", 2).split()
        if polish.length>1
          polish1 = polish[0].capitalize
          polish2 = polish[1].capitalize
          polish = polish1 + " " + polish2
        else
          polish = polish[0].capitalize
        end
        symmetry = cleane_arr(arr_res, 17, ":").split()
        if symmetry.length>1
          symmetry1 = symmetry[0].capitalize
          symmetry2 = symmetry[1].capitalize
          symmetry = symmetry1 + " " + symmetry2
        else
          symmetry = symmetry[0].capitalize
        end


        culet = cleane_arr(arr_res, 15, ":").capitalize
        culet[-1] =''
        fluorescence_intensity = cleane_arr(arr_res, 18, ":").split("'\'")[0]
        fluorescence_intensity[-1] = ''
        fluorescence_intensity[-1] = ''
        fluor = fluorescence_intensity.split()
        if fluor.length>1
          fluorescence_intensity = fluor[0].downcase.capitalize
          fluorescence_color = fluor[1].downcase.capitalize
        else
          fluorescence_intensity = fluor[0].downcase.capitalize
          fluorescence_color = ''
        end

         answer = {'shape' => cleane_arr(arr_res, 2, ":", 2).split()[0].capitalize,
                   'carat' => cleane_arr(arr_res, 6, ":").split(" ")[0].to_f.round(2),
                   'clarity' => cleane_arr(arr_res, 3, ":"),
                   'color' => cleane_arr(arr_res, 4, ":"),
                    'fancy_color' => '',
                    'fancy_color_intensity' => '',
                    'fancy_color_overtone' => '',
                    'fluorescence_intensity' =>  fluorescence_intensity,
                    'fluorescence_color' => fluorescence_color,
                    'make' => '',
                    'polish' =>polish,
                    'symmetry' => symmetry,
                    'length' => leigth_v.to_f,'width' => width.to_f,'height' => height.to_f,
                    'ratio' => '',
                    'depth' => cleane_arr(arr_res, 9, ":").split("%")[0].to_f,
                    'table_size' => cleane_arr(arr_res, 8, ":").split("%")[0].to_f,
                    'crown_height' => cleane_arr(arr_res, 10, ":").split("%")[0].to_f,
                    'pavilion_depth' =>  cleane_arr(arr_res, 12, ":").split("%")[0].to_f,
                    'girdle' => cleane_arr(arr_res, 14, ":"),
                    'culet_size' => '',
                    'culet_condition' => culet,
                    'graining' => '',
                    'remarks' => cleane_arr(arr_res, 1, ":"),
                    'certificate_path' => "http://www.eglusa.com/verify-a-report-results/?st_num=63978301"}



      when "AGS-"
        def get_val_td(resp, value)
          elw = resp.search "[text()*='#{value}']"
          return '777' if elw.empty? or elw.first.next_element.nil?
          el = elw.first.next_element.next_element.text
          return el.to_s
        end

        #parse leigth width height
        mess =  get_val_td(resp, 'Measurements')
        if mess.index('-')
          mess1 = mess.split(' - ')
          leigth_v = mess1[0]
          mess2 = mess1[1].split(' x ')
          width = mess2[0]
          height = mess2[1]
        else
          mess1 = mess.split(' x ')
          leigth_v = mess1[0]
          width = mess1[1]
          height = mess1[2]
        end

        #parse fluorescence
        fluorescence_color = ''
        fluor = get_val_td(resp, "Fluorescence").split()
        if fluor.length>1
          fluorescence_intensity = fluor[0].downcase.capitalize
          fluorescence_color = fluor[1].downcase.capitalize
        else
          fluorescence_intensity = fluor[0].downcase.capitalize
        end
        #cut necessary
        clarity =  get_val_td(resp, 'Clarity').split()[2]
        clarity =  get_val_td(resp, 'Clarity').split('(')[1].split(')')[0]
        color =  get_val_td(resp, 'Color Grade').split()[2]
        color =  get_val_td(resp, 'Color Grade').split('(')[1].split(')')[0]

        answer = {'shape' => get_val_td(resp, 'Shape and Style').split()[0],
                  'carat' => get_val_td(resp, 'Carat Weight').to_f.round(2),
                  'clarity' => clarity,
                  'color' => color,
                  'fancy_color' => '',
                  'fancy_color_intensity' => '',
                  'fancy_color_overtone' => '',
                  'fluorescence_intensity' => fluorescence_intensity,
                  'fluorescence_color' => fluorescence_color,
                  'make' => get_val_td(resp, 'Cut Grade').split()[1],
                  'polish' => get_val_td(resp, 'Polish'),
                  'symmetry' => get_val_td(resp, 'Symmetry'),
                  'length' => leigth_v.to_f, 'width' => width.to_f, 'height' => height.to_f,
                  'ratio' => '',
                  'depth' => get_val_td(resp, 'Total Depth: ').to_f,
                  'table_size' => get_val_td(resp, 'Table').to_f,
                  'crown_height' => get_val_td(resp, 'Crown Height').to_f,
                  'crown_angle' => get_val_td(resp, 'Crown Angle').to_f,
                  'pavilion_depth' => get_val_td(resp, 'Pavilion Depth').to_f,
                  'pavilion_angle' => get_val_td(resp, 'Pavilion Angle').to_f,
                  'girdle' => get_val_td(resp, 'Girdle'),
                  'culet_size' => '',
                  'culet_condition' => get_val_td(resp, 'Culet').to_s,
                  'graining' => '',
                  'remarks' => get_val_td(resp, 'Comments').to_s,
                  'certificate_path' => "http://www.agslab.com/reportTypes/dqd.php?StoneID=#{@cert_number}&Weight=#{@carat}&D=1"}

      when "HRD-"
        def get_val_td(resp, value)
          elw = resp.search "[text()*='#{value}']"
          return '777' if elw.empty? or elw.first.next_element.nil?
          el = elw.first.next_element.css('span').text
          return el.to_s
        end
        #parse leigth width height
        mess =  get_val_td(resp, 'Measurement')
        if mess.index('-')
          mess1 = mess.split(' - ')
          leigth_v = mess1[0]
          mess2 = mess1[1].split(' x ')
          width = mess2[0]
          height = mess2[1]
        else
          mess1 = mess.split(' x ')
          leigth_v = mess1[0]
          width = mess1[1]
          height = mess1[2]
        end
        #parse fluorescence
        fluorescence_color = ''
        fluor = get_val_td(resp, "Fluorescence").split()
        if fluor.length>1
          fluorescence_intensity = fluor[0].downcase.capitalize
          fluorescence_color = fluor[1].downcase.capitalize
        else
          fluorescence_intensity = fluor[0].downcase.capitalize
          fluorescence_intensity = 'None' if fluorescence_intensity == 'Nil'
        end
        #parse polish
        polish = get_val_td(resp, 'Polish').split()
        if polish.length>1
          polish1 = polish[0].capitalize
          polish2 = polish[1].capitalize
          polish = polish1 + " " + polish2
        else
          polish = polish[0].capitalize
        end
        culet = get_val_td(resp, 'Culet').lstrip
        #culet[0] = ''
        answer = {'shape' => get_val_td(resp, 'Shape').capitalize,
                  'carat' => get_val_td(resp, 'Carat(weight)').to_f.round(2),
                  'clarity' => get_val_td(resp, 'Clarity'),
                  'color' => get_val_td(resp, 'Colour Grade').split('(')[1][0,1],
                  'fancy_color' => '',
                  'fancy_color_intensity' => '',
                  'fancy_color_overtone' => '',
                  'fluorescence_intensity' => fluorescence_intensity,
                  'fluorescence_color' => fluorescence_color,
                  'make' => '',
                  'polish' => polish,
                  'symmetry' => get_val_td(resp, 'Symmetry').capitalize,
                  'length' => leigth_v.to_f, 'width' => width.to_f, 'height' => height.to_f,
                  'ratio' => '',
                  'depth' => get_val_td(resp, 'Total Dept').to_f,
                  'table_size' => get_val_td(resp, 'Table').to_f,
                  'crown_height' => get_val_td(resp, 'Crown Height ').to_f,
                  'pavilion_depth' =>  get_val_td(resp, 'Pavilion Depth').to_f,
                  'girdle' => get_val_td(resp, 'Girdle'),
                  'culet_size' => '',
                  'culet_condition' => culet.capitalize,
                  'graining' => '',
                  'remarks' => get_val_td(resp, 'Remarks'),
                  'certificate_path' => "http://www.hrdantwerplink.be/?record_number=#{@cert_number}&weight=#{@carat}&L="}
      else
        puts "You provide incorrect format cert"
    end

    answer.each{|key, value|
      answer.delete(key) if value == 'Non' || value == '' || value == 'nil' || value == 777.0  || value == 777 || value == "777"  || value == nil || value == 0.0
    }
    return answer
  end

  def check_method_and_querying
    case @cert_type
      when "EGLI"
        response = Nokogiri::HTML(simple_post_meth('http://www.eglinternational.org/egl/online-verification', {'cert'=>"#{@cert_number}", 'weight'=>"#{@carat}",'form_id'=>'egl_my_form'}))
        if !(response.to_s.index("Certificate number"))
          puts 'Incorrect form data or not found'
          return @answer = 2
        end
        @answer = parse_response(response, @cert_type)
      when "GIA-"
        response = simple_post_meth('http://www.gia.edu/otmm_wcs_int/proxy-report', {'ReportNumber' => "#{@cert_number}", 'url' => "https://myapps.gia.edu/ReportCheckPOC/pocservlet?ReportNumber=#{@cert_number}"})
        if (response.to_s.index("match found"))
          puts 'Incorrect form data or not found'
          return @answer = 2
        end
        @answer = parse_response(response, @cert_type)
      when "IGIUS"
        response = Nokogiri::HTML(simple_get_meth("http://igionline.com/igiweb/onlinereport/View_InstCert.cfm?pCert=#{@cert_number}&pWT=#{@carat}"))
        igi_cert_type = 2
        if (response.to_s.index("CAN'T BE FOUND"))
          puts "TYPE2"
          response = Nokogiri::HTML(simple_get_meth("http://igionline.com/igiweb/onlinereport/View_Cert.cfm?pCert=#{@cert_number}"))
          if (response.to_s.index("CAN'T BE FOUND"))
            return  @answer = 2
          end
          igi_cert_type = 1
        end
        @answer = parse_response(response, @cert_type, igi_cert_type)
      when "IGIAS"
        result = simple_post_meth('http://www.igiworldwide.com/search_report.aspx', {'ctl00$ContentPlaceHolder1$txtPrintNo'=>'S3F60037', 'ctl00$ContentPlaceHolder1$txtWeight'=>'1.13'})

        str_pos = result.index("__EVENTVALIDATION")
        result1 = result.slice(str_pos+49, 1200)
        str_end = result1.index('" />')
        validation = result1.slice(0, str_end)

        str_pos = result.index("__VIEWSTATE")
        result1 = result.slice(str_pos+37, 1200)
        str_end = result1.index('" />')
        viewstate = result1.slice(0, str_end)

        response = simple_post_meth('http://www.igiworldwide.com/search_report.aspx', {"__EVENTTARGET"=>"","__EVENTARGUMENT"=>"","__LASTFOCUS"=>"","__VIEWSTATE"=>viewstate,"__EVENTVALIDATION"=>validation,
                                                                                       "ddlanguage"=>"1", "q:"=>"", 'ctl00$ContentPlaceHolder1$ddlLang'=>"11",'ctl00$ContentPlaceHolder1$txtPrintNo'=>"#{@cert_number}",
                                                                                       'ctl00$ContentPlaceHolder1$txtWeight'=>"#{@carat}", 'ctl00$ContentPlaceHolder1$Search1'=>"ENTER",'ctl00$ContentPlaceHolder1$txtJPrintNo'=>"",
                                                                                       'ctl00$ContentPlaceHolder1$hidReportNo'=> "",
                                                                                       'ctl00$ContentPlaceHolder1$hidWeight'=> "",
                                                                                       'ctl00$ContentPlaceHolder1$hidIGI'=> "",
                                                                                       'ctl00$ContentPlaceHolder1$hidRepCategory'=>"",
                                                                                       'ctl00$ContentPlaceHolder1$hidLang'=>"0",
                                                                                       'ctl00$ContentPlaceHolder1$hidSpeed'=>"N"})
        response = Nokogiri::HTML(response)
        if !(response.to_s.index('tableBg'))
          return  @answer = 2
           puts 'Incorrect form data or not found'
        end
        @answer = parse_response(response, @cert_type)

      when "EGLU"
        response = simple_get_meth("http://myedge.eglusa.com/eglusacerts/#{@cert_number}D?callback=include_callback")
        if response.to_s.index('reportNumber') == nil
          puts 'Incorrect form data or not found'
          return  @answer = 2
        end
        @answer = parse_response(response, @cert_type)

      when "AGS-"
        response = Nokogiri::HTML(simple_get_meth("http://www.agslab.com/reportTypes/dqd.php?StoneID=#{@cert_number}&Weight=#{@carat}&D=1"))
        if response.css('table')[1].css('tr')[0].css('td')[2].text == ''
          puts 'Incorrect form data or not found'
          return  @answer = 2
        end
        @answer = parse_response(response, @cert_type)

      when "HRD-"
        response = Nokogiri::HTML(simple_get_meth("http://www.hrdantwerplink.be/?record_number=#{@cert_number}&weight=#{@carat}&L="))
        if response.css('table')[3].css('tr')[0].css('span').text.slice(0,9) == "Attention"
          puts 'Incorrect form data or not found'
          return @answer = 2
        end
        @answer = parse_response(response, @cert_type)
      else
        puts 'Incorrect form data or not found'
        @answer = 2
    end
  end
end

parse = ParseDiam.new("GIA-7136438784", 2.04)
parse.check_method_and_querying
puts parse.answer.keys