# Site for publishing the Muscat guidelines

This repository is a jekyll site for publishing the Muscat guidelines. The site uses the [rism-theme](https://github.com/rism-digital/rism-theme) and pulls most of the content from other repository. 

The main content is pulled from the [muscat-guidelines](https://github.com/rism-digital/muscat-guidelines) repository that contains Markdown files in various languages.

Additional translated labels are pulled from the [translations](https://github.com/rism-digital/translations) repository that contains translated labels used in Muscat. The translated labels are identified by translation keys, which mapping is pulled from the [muscat](https://github.com/rism-digital/muscat) repository.

The location of the three repositories is given in the `_config.yml` file:
```yml
guidelines_dir: "../muscat-guidelines"
muscat_dir: "../muscat"
translations_dir: "../translations"
```

The Jekyll hook in the [./_plugins](./_plugins) folder aggregate to content before the Jekyll site is actually build. The content consists of:
* The navigation menu for the guidelines that are written in `./_data`, with one `.yml` file by chapter.
* The actual content, with all the content for each chapter in a corresponding `.md` file written in `./output` (one per language)
* Common content copied to `./_includes`


