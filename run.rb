#!/usr/bin/env ruby

# function to open and read in file
def read_schema(schema)
  file = File.open(schema, 'r')
  data = file.read
  file.close
  data
end

# function that generates the pie chart data
def generate_data
  tokens = []
  # loop over schema files
  Dir.glob('assets/data/schema/*.xsd').map do |schema|
    data = read_schema(schema)
    data.scan(/<xs:\w+|\w+="\w+"|\w+="xs:\w+"/).uniq do |x|
      tokens << x unless tokens.include? x
    end
    data.scan(/<xs:\w+ \w+="\w+"/).uniq do |x|
      tokens << x unless tokens.include? x
    end
  end
  # create main data array
  structure = []
  tokens.sort.map.with_index do |x, i|
    structure[i] = [x]
    Dir.glob('assets/data/schema/*.xsd').map do |schema|
      filename = schema.split('/').last
      amount = read_schema(schema).scan(x).size
      structure[i] << [filename, amount] unless amount.zero?
    end
  end
  structure
end

# common function that prints the chart title
def chart_title(chart_type, ind)
  "#{ind + 1} - #{chart_type}"
end

# build all the website pages
def page_build(page_count, start = 0)
  (start..page_count).map do |i|
    instance_variable_set("@page#{i > 0 ? i : ''}", instance_variable_get("@page#{i > 0 ? i : ''}") + $page)
  end
end

# add navigation hyperlinks
def add_links(page_count)
  page = ''
  (0..page_count).map do |i|
    page += %(
          <li><a href="index#{i > 0 ? i : ''}.html">Page #{i + 1}</a></li>)
  end
  page
end

# remove special characters as they clash with JavaScript's naming conventions
def clean_chart(chart)
  chart.tr('<"=: ', '')
end

# create cloc data
cloc = `cloc . --ignored=ignored.txt --skip-uniqueness --quiet`

# create git log for histogram on homepage
`git log --pretty=format:"%ad" --date=short > log.txt`
file = File.open('log.txt', 'r')
logdata = file.read
file.close
logdata = logdata.lines.group_by(&:strip).map{|k, v| [k, v.size]}
logdata.unshift(%w[Date Amount])

extension = []
# get file extensions
Dir.glob('**/*').map do |x|
  ext = File.extname(x)
  if ext == ''
    extension << 'folders'
  else
    extension << ext[1..-1]
  end
  # sz = File.size(x)
  # sizes << sz
end

# hash of extensions
exthash = { 'css' => '#E6B0AA',
            'eot' => '#F4D03F',
            'folders' => '#E67E22',
            'html' => '#D7BDE2',
            'js' => '#28B463',
            'map' => '#111111',
            'md' => '#A9CCE3',
            'rb' => '#154360',
            'svg' => '#78281F',
            'txt' => '#17202A',
            'ttf' => '#000000',
            'woff' => '#8E44AD',
            'woff2' => '#999999',
            'xml' => '#E67E22',
            'xsd' => '#34495E'}

# extensions
allFiles = extension.flatten.group_by{|x| x}.map{|k, v| [k, v.size]}

# colors for the pie chart pieces
schema_colors = { 'bar.xsd' => '#E6B0AA',
                  'bookstore.xsd' => '#F4D03F',
                  'concept.xsd' => '#D7BDE2',
                  'dinner-menu.xsd' => '#28B463',
                  'foo.xsd' => '#A9CCE3',
                  'note.xsd' => '#154360',
                  'note2.xsd' => '#A3E4D7',
                  'reference.xsd' => '#78281F',
                  'saml20assertion_schema.xsd' => '#7D6608',
                  'saml20protocol_schema.xsd' => '#E67E22',
                  'sitemap.xsd' => '#FFCCCC',
                  'task.xsd' => '#784212',
                  'topic.xsd' => '#34495E',
                  'xenc_schema.xsd' => '#17202A',
                  'xmldsig_schema.xsd' => '#8E44AD' }

# function that draws the pie chart
def drawchart(which, data, num, colors, title)
  s = "
    var pie = new d3pie('pie_chart_div_#{which}', {
        'header': {
            'title': {
                'text': '#{chart_title(title, num)}',
                'fontSize': 14,
                'font': 'open sans'
            }
        },
        'footer': {
            'text': '',
            'color': '#999999',
            'fontSize': 10,
            'font': 'open sans',
            'location': 'bottom-center'
        },
        'size': {
            'canvasWidth': 450,
            'canvasHeight': 400,
            'pieOuterRadius': '55%'
        },

        'data': {
            'sortOrder': 'value-desc',
            'smallSegmentGrouping': {
                'enabled': true,
                'value': 3
            },
            'content': ["
  data.each do |x|
    s += "{'label':'#{x[0].split('.').first}','value':#{x[1]},'color':'#{colors[x[0]]}'},"
  end
  s.chop!
  s += "
            ]
        },
        callbacks: {
          onMouseoverSegment: function(info) {
            console.log('mouseover:', info);
          },
          onMouseoutSegment: function(info) {
            console.log('mouseout:', info);
          }
        },
        'labels': {
            'outer': {
                'pieDistance': 20
            },
            'inner': {
                'format': 'value',
                'hideWhenLessThanPercentage': 3
            },
            'mainLabel': {
                'fontSize': 11
            },
            'percentage': {
                'color': '#ffffff',
                'decimalPlaces': 0
            },
            'value': {
                'color': '#ffffff',
                'fontSize': 12
            },
            'lines': {
                'enabled': true
            },
            'truncation': {
                'enabled': true
            }
        },
        'tooltips': {
            'enabled': true,
            'type': 'placeholder',
            'string': '{label}: {value}, {percentage}%',
            'styles': {
                'fadeInSpeed': 586,
                'backgroundOpacity': 0.7,
                'color': '#ffffff',
                'fontSize': 12
            }
        },
        'effects': {
            'pullOutSegmentOnClick': {
                'effect': 'linear',
                'speed': 400,
                'size': 10
            }
        },
        'misc': {
            'colors': {
                'background': '#ffffff'
            },
            'gradient': {
                'enabled': true,
                'percentage': 100
            }
        }
    });\n"
  s
end

# data variable
structure = generate_data

# start common page region
$page = %(<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- The above 3 meta tags *must* come first in the head;
         any other head content must come *after* these tags -->
    <title>Ruby d3pie text mining dashboard</title>
    <meta name="description" content="Analytics dashboard built from Ruby using
          the d3pie library. It text mines a folder of XML Schema to generate
          statistics about tags and attributes.">
    <meta name="theme-color" content="#312598"/>
    <link rel="stylesheet" href="assets/bootstrap/css/bootstrap.min.css">
    <link rel="stylesheet" href="assets/bootstrap/css/bootstrap-theme.min.css">
    <style>
      .container-fluid { padding: 0px; }
      .navbar, .navbar-default { padding: 5pt; background-color: rgba(49,37,152,0.8) !important; font-size: 12pt; }
      .navbar, .navbar-default li a { color: #000 !important; }
      .navbar-default .navbar-brand, .navbar-default .navbar-brand:hover { color: #fff; font-size: 15pt; }
      div[id^="pie_chart_div_"] > svg { margin: auto; }
      footer { background-color: rgba(49,37,152,0.8); min-height: 200px; color: #fff !important; }
      footer ul a { color: #fff !important; }
      .selected { background-color: aliceblue; font-weight: bold; }
      .navbar-default li:hover a { background-color: red !important; }
      .nuchecker a { font-weight: bold; }
      h1 { text-align: center; background-color: rgba(49,37,152,0.8); padding: 14px; color: #fff; }
      pre { white-space: pre-wrap; white-space: moz-pre-wrap;
            white-space: -pre-wrap; white-space: -o-pre-wrap;
            word-wrap: break-word; }
      .homepage { padding: 5px 30px 5px 30px; }
    </style>
  </head>
    <body>
      <!-- Static navbar -->
      <nav class="navbar navbar-default" id="head1">
        <div class="container-fluid">
          <div class="navbar-header">
            <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
              <span class="sr-only">Toggle navigation</span>
              <span class="icon-bar"></span>
              <span class="icon-bar"></span>
              <span class="icon-bar"></span>
            </button>
            <a class="navbar-brand" href="index.html">Analytics Dashboard</a>
          </div>
          <div id="navbar" class="navbar-collapse collapse">
            <ul class="nav navbar-nav">)

# home page plus other pages with 50 charts per page
page_count = structure.size / 50 + 1
(0..page_count).map do |i|
  instance_variable_set("@page#{i > 0 ? i : ''}", $page)
end
# restart common page region
$page = add_links(page_count)
# continue to build all the pages
page_build(page_count)
# restart common page region
$page = %(</ul>
        </div>
      </div>
    </nav>
    <div class="container-fluid">)
# continue to build all the pages
page_build(page_count)
# start home page stats
@page += %(
      <h1>Ruby d3pie based XML Schema text mining application</h1>
      <div class="row homepage">
        <h2>Featured Statistics</h2>
        <h3>Built With</h3>
        <div>
          <ul>
            <li><a href="https://www.ruby-lang.org" target="_blank" rel="noopener">Ruby</a></li>
            <li><a href="http://d3pie.org/" target="_blank" rel="noopener">d3pie</a></li>
            <li><a href="https://d3js.org/" target="_blank" rel="noopener">D3</a></li>
            <li><a href="https://developer.mozilla.org/en-US/docs/Web/Guide/HTML/HTML5" target="_blank" rel="noopener">HTML5</a></li>
            <li><a href="https://developer.mozilla.org/en-US/docs/Web/CSS/CSS3" target="_blank" rel="noopener">CSS3</a></li>
            <li><a href="https://getbootstrap.com/" target="_blank" rel="noopener">Bootstrap</a></li>
            <li><a href="https://jquery.com/" target="_blank" rel="noopener">jQuery</a></li>
            <li><a href="https://en.wikipedia.org/wiki/JavaScript" target="_blank" rel="noopener">JavaScript</a></li>
            <li><a href="https://en.wikipedia.org/wiki/XML" target="_blank" rel="noopener">XML</a></li>
            <li><a href="https://en.wikipedia.org/wiki/XML_schema" target="_blank" rel="noopener">XML Schema</a></li>
            <li><a href="https://en.wikipedia.org/wiki/Regular_expression" target="_blank" rel="noopener">Regular Expressions</a></li>
            <li><a href="https://git-scm.com/" target="_blank" rel="noopener">Git</a></li>
            <li><a href="https://desktop.github.com/" target="_blank" rel="noopener">GitHub Desktop</a></li>
            <li><a href="https://pages.github.com" target="_blank" rel="noopener">GitHub Pages</a></li>
            <li><a href="https://www.jetbrains.com/ruby" target="_blank" rel="noopener">RubyMine</a></li>
            <li><a href="https://flagcounter.com/" target="_blank" rel="noopener">Flag Counter</a></li>
            <li><a href="https://buttons.github.io/" target="_blank" rel="noopener">Github:buttons</a></li>
            <li><a href="https://github.com/AlDanial/cloc" target="_blank" rel="noopener">Count lines of code</a></li>
          </ul>
        </div>
        <h3>Lines of code in this project</h3>
        <pre>
          <code>
            #{cloc}
          </code>
        </pre>
      </div>
      <div class="row">
        <div class="col-sm-6 col-md-4 col-lg-3" id="pie_chart_div_homepage_all"></div>
        <div class="col-sm-6 col-md-4 col-lg-3" id="pie_chart_div_homepage_hist"></div>
      </div>\n)

# restart all the chart pages
$page = %(
      <h1>Branch count grouped by file</h1>)
# continue to build all the pages
page_build(page_count, 1)
# add chart divs to each page
structure.map.with_index do |chart, i|
  data0 = clean_chart(chart[0])
  i = i / 50 + 1
  instance_variable_set("@page#{i}",
                        instance_variable_get("@page#{i}") + "\n      <div class=\"col-sm-6 col-md-4 col-lg-3\" id=\"pie_chart_div_#{data0}\"></div>")
end
# restart common page region
$page = '
    </div>
    <footer>
      <div class="container">
        <ul class="list-unstyled">
          <li>
            <a class="github-button" href="https://github.com/jbampton"
               data-size="large" data-show-count="true"
               aria-label="Follow @jbampton on GitHub">Follow @jbampton</a>
          </li>
          <li>
            <a class="github-button" href="https://github.com/jbampton/charts"
               data-icon="octicon-star" data-size="large" data-show-count="true"
               aria-label="Star jbampton/charts on GitHub">Star</a>
          </li>
          <li>
            <a class="github-button" href="https://github.com/jbampton/charts/subscription"
               data-icon="octicon-eye" data-size="large" data-show-count="true"
               aria-label="Watch jbampton/charts on GitHub">Watch</a>
          </li>
          <li>
            <a class="github-button" href="https://github.com/jbampton/charts/fork"
               data-icon="octicon-repo-forked" data-size="large"
               data-show-count="true" aria-label="Fork jbampton/charts on GitHub">Fork</a>
          </li>'
# continue to build all the pages
page_build(page_count)
# restart common page region
$page = add_links(page_count)
# continue to build all the pages
page_build(page_count)
# restart common page region
$page = %(
          <li><a href="#head1">Back to top</a></li>
          <li class="nuchecker">
            <a target="_blank" rel="noopener">Valid HTML</a>
          </li>
        </ul>
        <a href="https://info.flagcounter.com/9VsC"
           target="_blank" rel="noopener">
          <img src="https://s01.flagcounter.com/countxl/9VsC/bg_FFFFFF/txt_000000/border_CCCCCC/columns_2/maxflags_250/viewers_0/labels_1/pageviews_0/flags_0/percent_0/"
               alt="Flag Counter">
        </a>
        <a id="theend"></a>
      </div>
    </footer>
    <script src="assets/bootstrap/js/jquery.min.js"></script>
    <script src="assets/bootstrap/js/bootstrap.min.js"></script>
    <script src="assets/js/d3/d3.js"></script>
    <script src="assets/js/d3pie.min.js"></script>
    <script>)
# continue to build all the pages
page_build(page_count)
# add all the javascript for each pie chart to each page
# home page
@page += drawchart('homepage_all', allFiles, 0, exthash, 'Branch count of files grouped by file extension')
# other pages
structure.map.with_index do |chart, ind|
  data0 = clean_chart(chart[0])
  data1 = chart[1..-1]
  i = ind / 50 + 1
  instance_variable_set("@page#{i}",
                        instance_variable_get("@page#{i}") + drawchart(data0, data1, ind, schema_colors, chart[0]))
end

# restart common page
$page = %(
      $(document).ready(function () {
         "use strict";
         var last = $(location).attr("href").split("/").pop().split(".")[0].replace(/index/, "");
         var tab = 1;
         if (last !== "") {
           tab = parseInt(last) + 1;
         }
         $(".navbar-nav li:nth-child(" + tab + ")").addClass("selected");
         tab--;
         if (tab === 0) {
           tab = "";
         }
        $(".nuchecker a").attr("href", "https://validator.w3.org/nu/?doc=http%3A%2F%2Fthebeast.me%2Fcharts%2Findex" + tab + ".html");
    });
    </script>
    <script async defer src="https://buttons.github.io/buttons.js"></script>
  </body>
</html>)
# finish building all the pages
page_build(page_count)
# write all the HTML pages to files and build the site map
sitemaptime = Time.now.strftime '%FT%T%:z'
sitemap = %(<?xml version="1.0" encoding="UTF-8"?>
<urlset
  xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9
  http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
  <url>
    <loc>http://thebeast.me/charts/</loc>
    <lastmod>#{sitemaptime}</lastmod>
    <priority>1.00</priority>
  </url>)
(0..page_count).map do |i|
  file = File.open("index#{i > 0 ? i : ''}.html", 'w')
  file.write(instance_variable_get("@page#{i > 0 ? i : ''}"))
  file.close
  sitemap += %(
  <url>
    <loc>http://thebeast.me/charts/index#{i > 0 ? i : ''}.html</loc>
    <lastmod>#{sitemaptime}</lastmod>
    <priority>0.80</priority>
  </url>)
end
sitemap += '
</urlset>'
file = File.open('sitemap.xml', 'w')
file.write(sitemap)
file.close
