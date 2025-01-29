---
layout: guidelines
menubar: introduction
permalink: /index.html
---

{% capture filename %}common/homepage.{{ site.active_lang }}.md{% endcapture %}
{% include {{ filename }} %}

<article class="message">
  <div class="message-header">
    <p>Latest changes</p>
  </div>
  <div class="message-body">
    {% capture changes_content %}
      {% include common/changes.en.md %}
    {% endcapture %}
    {{ changes_content | markdownify }}
   </div>
</article>
