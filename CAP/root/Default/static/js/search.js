//Scripts to load Dojo forms

//First load the necessary Dojo modules
dojo.require("dijit.Toolbar");
dojo.require("dijit.form.Form");
dojo.require("dijit.form.Button");
dojo.require("dijit.TooltipDialog");
dojo.require("dijit.Menu");
dojo.require("dijit.form.TextBox");
dojo.require("dijit.form.NumberTextBox");


dojo.require("dijit.layout.BorderContainer");
dojo.require("dijit.layout.ContentPane");
dojo.require("dojo.parser");



//Create the content panes
dojo.addOnLoad(function() {
            
         
            var border_container = new dijit.layout.BorderContainer({
                design: "sidebar",
                gutters: true,
                liveSplitters: true,
                style: "width: 100%;",
            },
	    "border_container");   
            
            var results_pane = new dijit.layout.ContentPane({
                content: "hello world",
                style: "width: 400px;",
                splitter: true,
                region: "leading",
            },
            document.createElement("div")
            );
            
            var document_pane= new dijit.layout.ContentPane({
                content: "<p>Document Pane</p>",
                splitter: true,
                region: "center",
            },
            document.createElement("div")
            );
            
            border_container.startup();
            border_container.addChild(results_pane);
            border_container.addChild(document_pane);

        });

    
//Toolbar

       var any_language     = 0;
       var include_language = 0;
       var any_medium       = 0;
       var include_medium   = 0;
       var any_contrib      = 0;
       var include_contrib  = 0;

        // Function for creating generic menu items. 
        function CreateMenuItem (params) {
            var sortmenuItem;
            sortmenuItem = new dijit.MenuItem({
                label: params[0],
                onClick: function() {
                    location=params[1];
                }
            });
            return sortmenuItem;

        };

        // Function for creating generic dropdown buttons. 
        function CreateButton (menuname,button_params) {
            var newbutton = new dijit.form.DropDownButton({
                label: button_params[0],
                name: button_params[1],
                id: button_params[2],
                dropDown: menuname
            });
            return newbutton;

        };
