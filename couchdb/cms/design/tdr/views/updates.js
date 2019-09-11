module.exports = {
  map: function(doc) {
    var languages = ["en", "fr"];

    if (!("block" in doc) && "isUpdate" in doc) {
      if (Array.isArray(doc["portal"])) {
        doc["portal"].forEach(function(portal) {
          languages.forEach(function(lang) {
            if (lang in doc) {
              emit([portal, lang, doc.created], doc[lang]);
            }
          });
        });
      }
    }
  }
};
