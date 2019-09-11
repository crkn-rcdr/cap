module.exports = {
  map: function(doc) {
    var languages = ["en", "fr"];

    if (!("block" in doc) && doc.type != "redirect") {
      doc.portal.forEach(function(portal) {
        var paths = {};

        languages.forEach(function(lang) {
          if (lang in doc) {
            var alternates = [];
            languages.forEach(function(hreflang) {
              if (hreflang in doc) {
                alternates.push([hreflang, doc[hreflang].path]);
              }
            });

            paths[doc[lang].path] = alternates;
          }
        });

        Object.keys(paths).forEach(function(path) {
          emit([portal, path], paths[path]);
        });
      });
    }
  }
};
