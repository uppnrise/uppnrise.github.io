require "fileutils"
require "minitest/autorun"
require "nokogiri"
require "open3"
require "pathname"

class SiteTest < Minitest::Test
  ROOT = Pathname.new(__dir__).join("..").expand_path
  DESTINATION = ROOT.join("_site_test")
  BASEURL_DESTINATION = ROOT.join("_site_test_baseurl")

  def setup
    return if self.class.instance_variable_get(:@built)

    build_site
    self.class.instance_variable_set(:@built, true)
  end

  def test_listing_pages_have_specific_metadata
    {
      "projects/index.html" => ["Projects", "Selected software engineering projects"],
      "blog/index.html" => ["Blog", "Articles about backend engineering"]
    }.each do |path, (title, description)|
      page = parse(path)

      assert_includes page.at_css("title").text, title
      assert_includes page.at_css('meta[name="description"]')["content"], description
    end
  end

  def test_every_blog_post_renders_its_front_matter_title_once
    post_files.each do |source|
      slug = source.basename(".md").to_s.sub(/^\d{4}-\d{2}-\d{2}-/, "")
      page = parse(Dir[DESTINATION.join("**", "#{slug}.html")].first)
      title = front_matter_title(source)

      headlines = page.css('article h1[itemprop="headline"]')
      assert_equal 1, headlines.count, source.basename.to_s
      assert_equal title, headlines.first.text.strip
    end
  end

  def test_education_lists_are_not_nested_inside_paragraphs
    layout = ROOT.join("_layouts/resume.html").read

    refute_match(/<p[^>]*>\s*<ul/m, layout)
  end

  def test_social_links_have_accessible_names
    page = parse("index.html")

    page.css(".icon-links a").each do |link|
      accessible_name = [link["aria-label"], link.text.strip].compact.join
      refute_empty accessible_name, link["href"]
    end
  end

  def test_internal_asset_and_navigation_urls_support_a_baseurl
    page = parse("index.html", baseurl: "/preview")
    urls = page.css('link[rel="stylesheet"], link[rel~="icon"], img.avatar, .main-navigation a')
               .map { |node| node["href"] || node["src"] }
               .select { |url| url.start_with?("/") }

    assert urls.all? { |url| url.start_with?("/preview/") }, urls.inspect
  end

  def test_enabled_resume_sections_use_the_public_configuration_names
    layout = ROOT.join("_layouts/resume.html").read

    %w[projects skills recognition links associations].each do |section|
      assert_includes layout, "site.section_#{section}"
      refute_includes layout, "site.resume_section_#{section}"
    end
  end

  def test_dormant_data_has_no_placeholder_records
    %w[associations links recognitions skills].each do |name|
      content = ROOT.join("_data/#{name}.yml").read

      refute_match(/example\.org|url:\s*["']?#|description:\s*$|summary:\s+[A-Z]\s*$|skill:\s+[A-Z]\s*$/i, content)
    end
  end

  def test_internal_page_links_resolve
    html_files.each do |source|
      parse(source).css("a[href]").each do |link|
        href = link["href"]
        next unless href.start_with?("/")

        path = href.split("#", 2).first.split("?", 2).first
        target = if path.end_with?("/")
                   DESTINATION.join(path.delete_prefix("/"), "index.html")
                 else
                   DESTINATION.join(path.delete_prefix("/"))
                 end
        assert target.exist?, "Broken link #{href} in #{source.relative_path_from(DESTINATION)}"
      end
    end
  end

  def test_ci_pins_the_ruby_version
    workflow = ROOT.join(".github/workflows/site-checks.yml").read

    assert_match(/^\s+ruby-version:\s*["']?3\.4["']?\s*$/, workflow)
  end

  def test_lockfile_supports_the_ci_platform
    lockfile = ROOT.join("Gemfile.lock").read

    assert_match(/^  x86_64-linux$/, lockfile)
  end

  private

  def parse(path, baseurl: nil)
    destination = DESTINATION
    if baseurl
      destination = BASEURL_DESTINATION
      build_site(baseurl: baseurl, destination: destination)
    end

    Nokogiri::HTML5(File.read(Pathname.new(path).absolute? ? path : destination.join(path)))
  end

  def build_site(baseurl: nil, destination: DESTINATION)
    FileUtils.rm_rf(destination)
    command = ["bundle", "exec", "jekyll", "build", "--destination", destination.to_s]
    command.concat(["--baseurl", baseurl]) if baseurl
    output, status = Open3.capture2e(*command, chdir: ROOT.to_s)
    raise "Jekyll build failed:\n#{output}" unless status.success?
  end

  def post_files
    ROOT.join("_posts").children.select { |path| path.extname == ".md" }
  end

  def html_files
    DESTINATION.glob("**/*.html")
  end

  def front_matter_title(path)
    path.read[/^title:\s*["'](.*)["']\s*$/, 1]
  end
end
