# Site for publishing the Muscat guidelines

This repository is a Jekyll site for publishing the Muscat guidelines. The site uses the [rism-theme](https://github.com/rism-digital/rism-theme) and pulls content from other repositories. 

The main content is pulled from the [muscat-guidelines](https://github.com/rism-digital/muscat-guidelines) repository that contains Markdown files in various languages.

Additional translated labels are pulled from the [translations](https://github.com/rism-digital/translations) repository that contains the translated labels used in Muscat. The translated labels are identified by translation keys. The mapping of the keys is given in the configuration files available in the [muscat](https://github.com/rism-digital/muscat) repository.

The location of the three repositories used for building the site is given in the `_config.yml` file:
```yml
guidelines_dir: "../muscat-guidelines"
muscat_dir: "../muscat"
translations_dir: "../translations"
```

The Jekyll hook in the [./_plugins](./_plugins) folder aggregates to content before the Jekyll site is actually built. 

The content consists of:
* The navigation menu for the guidelines that are written in `./_data`, with one `.yml` file by chapter.
* The actual content, with all the files for each chapter put together in a corresponding `.md` file written in `./output` (one per language)
* Content common to all languages copied to `./_includes`

The languages available in the site is also given in the the `_config.yml` file:
```
languages: ["en", "de", "fr"]
```
