require 'yaml'
require 'i18n'

Jekyll::Hooks.register :site, :after_init do |site|

    ################################
    # Function to load a configuration - remove the first line since this is not compatible outside Rails
    def load_muscat_config model
        configfile = "#{@muscat_config}/#{model}Labels.yml"
        lines = File.readlines(configfile)
        if lines[0].include?('--- !map:ActiveSupport::HashWithIndifferentAccess')
            lines.shift # Remove the first line
        end
        return YAML.safe_load(lines.join, symbolize_names: true)
    end

    ################################
    # Function to retrieve a translation for a key with a specific model (nil == "source")
    def get_muscat_translation(key, model)
        label = "unspecified"
        case model
            when nil 
                label = I18n.t(@source_config[key.to_sym][:label]) rescue "missing label in source"
            when "institution" 
                label = I18n.t(@institution_config[key.to_sym][:label]) rescue "missing label in instition"
            when "person" 
                label = I18n.t(@person_config[key.to_sym][:label]) rescue "missing label in person"
            when "publication" 
                label = I18n.t(@publication_config[key.to_sym][:label]) rescue "missing label in publication"
            end
        label
    end

    ################################
    # Function to retrieve a translation for a key in the guidelines specific translations
    def get_guidelines_translation(key)
        label = I18n.t(("guidelines." + key).to_sym) rescue "missing label in guidelines"
        label
    end

    ################################
    # Function for generating the navigation map
    # Takes a chapter entry from the guidelines.yml and add a navigation hash to @navigation
    def generate_navigation chap
        id = chap[:guidelines_title]
        navigation = Hash.new
        navigation[:name] = Hash.new

        # A hash for the content by language
        content = Hash.new
        @languages.each do |lang|
            title = get_guidelines_translation(id)
            navigation[:name][lang] = "#{@chapterNb} – #{title}"
            content[lang] = format(@header, title, lang, id, id)
        end
        navigation[:id] = id
        navigation[:link] = "/#{id}.html"

        @navigation[:items] << navigation
        @content[id] = content

        @chapterNb += 1
    end

    ################################
    # Function for generating the content .md navigation .yml file for a chapter
    # Takes a chapter entry form the guidelines.yml
    # Uses the pre-generated @navigation map and extended for the chapter before writing the .yml
    # Sets @chapter and @sidebar for processing sections and subsections
    def generate_chapter chap
        id = chap[:guidelines_title]
        # Make a duplicate so we keep @navigation untouch
        navigation = YAML.load(@navigation.to_yaml)
        # This is the sidebar for the current chapter to which we will be adding section links
        @sidebar = navigation[:items].find { |hash| hash[:id] == id  }
        # This is the content for the current chapter
        @chapter = @content[id]
 
        @languages.each do |lang|
            # @chapter[lang] += "# #{@chapterNb} – #{title}\n"
            if chap[:helpfile]
                @chapter[lang] += File.read("#{@guidelines}/#{lang}/#{chap[:helpfile]}.md")
            end
        end

        sections =  chap[:sections]
        if sections
            @sectionNb = 1
            sections.each do |sec|
                generate_section(sec) if sec
            end
        end

        @languages.each do |lang|
            # Write the .md file for the current chapter / lang
            File.write("#{@output_dir}/#{id}.#{lang}.md", @chapter[lang])     
        end

        # Painful conversion of the symbols to string 
        navigation = navigation.deep_transform_keys(&:to_s)
        # Write the navigation menu
        File.write("#{@menu_dir}/#{id}.yml", [navigation].to_yaml)

        @chapterNb += 1
    end
    
    ################################
    # Function for adding the content of the section to the chapter content .md and navigation .yml
    # Rely on the current @chapter and @sidebar
    def generate_section sec
        id = sec[:guidelines_title]
        title = get_guidelines_translation(id)

        # A hash for the section navigation
        navigation = Hash.new
        navigation[:name] = Hash.new

        @languages.each do |lang|
            # Add the section header together with a custom anchor
            @chapter[lang] += "\n# #{@chapterNb}.#{@sectionNb} – #{title} {##{id}}\n"
            # Add the navigation label for the current language
            navigation[:name][lang] = "#{@chapterNb}.#{@sectionNb} – #{title}"
            if sec[:helpfile]
                @chapter[lang] += File.read("#{@guidelines}/#{lang}/#{sec[:helpfile]}.md") rescue "#{sec[:helpfile]}.md MISSING\n"
            end
        end
        # Add a navigation link using the custom anchor
        navigation[:link] = "#{@sidebar[:link]}##{id}"
        # Create an array if this is the first section in the chapter
        @sidebar[:items] = Array.new if !@sidebar[:items]
        # Add the navigation to it
        @sidebar[:items] << navigation

        subsections = sec[:subsections]
        if subsections
            @subsectionNb = 1
            subsections.each do |subsec|
                generate_subsection(subsec, sec[:model]) if subsec
            end  
        end 
        
        @sectionNb += 1
    end
      
    ################################
    # Function for adding the content of the subsection to the chapter content .md
    # Rely on the current @chapter
    def generate_subsection(subsec, model)
        title = "[unspecified]"
        if subsec[:title]
            title = get_muscat_translation(subsec[:title], model)
        elsif subsec[:guidelines_title]
            title = get_guidelines_translation(subsec[:guidelines_title])
        end

        @languages.each do |lang|
            @chapter[lang] += "\n## #{@chapterNb}.#{@sectionNb}.#{@subsectionNb} – #{title}\n"
            if subsec[:helpfile]
                @chapter[lang] += File.read("#{@guidelines}/#{lang}/#{subsec[:helpfile]}.md") rescue "#{subsec[:helpfile]}.md MISSING\n"
            end
        end
        
        @subsectionNb += 1
    end
    
    ################################
    # Script
    ################################

    # Where to find the guidelines .yml file and *.md files in the muscat-guidelines repository
    @guidelines = "#{site.config['guidelines_dir']}/default"
    # Where to find the guidelines *.md files in the muscat-guidelines repository to be copied to _includes
    @guidelines_include = "#{site.config['guidelines_dir']}/common"
    # Where to find the guidelines locales *.yml files in the muscat-guidelines repository
    @guidelines_locales = "#{site.config['guidelines_dir']}/locales"

    # Where to find the translation files from the translations repository
    @translations = "#{site.config['translations_dir']}/locales"

    # Where to find the configuration files from the muscat repository
    @muscat_config = "#{site.config['muscat_dir']}/config/editor_profiles/default/configurations/"

    # Load the configs
    @source_config = load_muscat_config "Source"   
    @institution_config = load_muscat_config "Institution"
    @person_config = load_muscat_config "Person"
    @publication_config = load_muscat_config "Publication"

    # Load all the translations
    I18n.load_path += Dir[File.expand_path("#{@translations}/*.yml")]
    I18n.load_path += Dir[File.expand_path("#{@guidelines_locales}/*.yml")]
    I18n.default_locale = :en

    # The languages selected for the guidelines as set in _config.yml
    @languages = site.config['languages']

    # The output directory path for the .md files
    @output_dir = "./output"
    # The output directory file for the menu .yml
    @menu_dir = "./_data"

    # header for the .md pages with
    # ---
    # layout: guidelines
    # title: %s
    # lang: %s
    # permalink: %s
    # menubar: %s
    # ---
    @header = "---\nlayout: guidelines\ntitle: %s\nlang: %s\npermalink: %s.html\nmenubar: %s\n---\n" 
    
    @chapter = nil
    @sidebar = nil
    
    # numbering
    @chapterNb = 1
    @sectionNb = 1
    @subsectionNb = 1

    # Store a global hash with all the chapter navigation
    @navigation = Hash.new
    # This will need to be translated from the guidelines locale
    @navigation[:label] = Hash.new
    @languages.each do |lang|
        @navigation[:label][lang] = get_guidelines_translation("content")
    end
    @navigation[:items] = Array.new

    # Store a global hash with all the content
    @content = Hash.new

    # Ensure the output directory exists
    Dir.mkdir(@output_dir) unless Dir.exist?(@output_dir)

    configfile = "#{site.config['guidelines_dir']}/default/guidelines.yml"
    @tree = YAML.safe_load(File.read(configfile), symbolize_names: true)

    # First pass - generate the navigation map
    @tree[:chapters].each do |chap| 
        generate_navigation(chap)
    end

    # Second pass - reset the chapter counter and generate the content and navigation files
    @chapterNb = 1
    @tree[:chapters].each do |chap| 
        generate_chapter(chap)
    end

    # _includes dir of the site
    include_dir = File.join(site.source, "_includes/common") # Destination _includes folder
    # Make sure the target directory exists
    Dir.mkdir(include_dir) unless Dir.exists?(include_dir)
    
    # Copy each file from ./common in the guidelines to _includes
    # Also change .md to .html because otherwise jekyll expects a .xx.md include with the corresponding language
    Dir.glob("#{@guidelines_include}/*").each do |file|
        FileUtils.cp(file, include_dir)
        basename = File.basename(file, ".md") # Get the base name (without .md)
        htmlFilename = "#{basename}.html"   # Append .html to the base name
        FileUtils.mv(File.join(include_dir, File.basename(file)), File.join(include_dir, htmlFilename))
        Jekyll.logger.info "Copying:", "Copied #{file} to #{include_dir} as .html"
    end

    # Log message to indicate the pre-build hook was triggered
    Jekyll.logger.info "GuidelinesGenerator:", "Files generated in #{@output_dir} during :before_init hook"
end


# Class for transforming the symbols to string
class Hash
    def deep_transform_keys(&block)
      # Transform the keys at the current level
      result = transform_keys(&block)
  
      # Recursively apply deep_transform_keys to any nested hashes
      result.each do |key, value|
        if value.is_a?(Hash)
          result[key] = value.deep_transform_keys(&block)
        elsif value.is_a?(Array)
          # Recursively apply to any hashes within arrays
          result[key] = value.map do |item|
            item.is_a?(Hash) ? item.deep_transform_keys(&block) : item
          end
        end
      end
  
      result
    end
end