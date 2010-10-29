
        dojo.require("dijit.layout.BorderContainer");
        dojo.require("dijit.layout.ContentPane");
        dojo.require("dojo.parser");
        dojo.addOnLoad(function() {
            
         
            var border_container = new dijit.layout.BorderContainer({
                design: "headline",
                gutters: true,
                liveSplitters: true,
            },
	    "border_container");   

            var top_pane = new dijit.layout.ContentPane({
                href: "http://localhost:3000/ajax/hello",
                style: "width: 100%;height: 120px;",
                splitter: true,
                region: "top",
            },
            document.createElement("div")
            );
            
            var results_pane = new dijit.layout.ContentPane({
                content: "stuff",
                style: "width: 400px;",
                splitter: true,
                region: "left",
            },
            document.createElement("div")
            );
            
            var document_pane= new dijit.layout.ContentPane({
                content: "<p>Document Pane<\/p>",
                // minsize: '400';
                splitter: true,
                region: "center",
            },
            document.createElement("div")
            );
 

            var right_pane = new dijit.layout.ContentPane({
                content: "stuff",
                style: "width: 400px;",
                splitter: true,
                region: "right",
            },
            document.createElement("div")
            );
            
            var bottom_pane = new dijit.layout.ContentPane({
                content: "stuff",
                style: "width: 100%;z-index:1000",
                splitter: true,
                region: "bottom",
            },
            document.createElement("div")
            ); 
                      
            border_container.startup();
            border_container.addChild(results_pane);
            border_container.addChild(document_pane);
            border_container.addChild(top_pane);
            border_container.addChild(bottom_pane);
            border_container.addChild(right_pane);

        });
