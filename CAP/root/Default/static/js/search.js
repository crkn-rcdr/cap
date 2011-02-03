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

dojo.require("dijit.Tree");
dojo.require("dojo.data.ItemFileReadStore");
dojo.require("dijit.tree.ForestStoreModel");


 
dojo.addOnLoad(function() {
            
            //Create border container
            var border_container = new dijit.layout.BorderContainer({
                design: "headline",
                gutters: false,
                liveSplitters: false
            },
	    "border_container");   

             var top_pane = new dijit.layout.ContentPane({
                splitter: false,
                region: "top"
            },
            "header_pane"
            );


            var left_pane = new dijit.layout.ContentPane({
                //href: "test_content.html",
                splitter: false,
                region: "left"
            },
            "content_pane"
            );
            
            var results_pane = new dijit.layout.ContentPane({
                splitter: false,
                region: "center"
            },
            "tree_pane"
            );
            
            var document_pane= new dijit.layout.ContentPane({
                // content: "<p>Document Pane<\/p>",
                // minsize: '400';
                splitter: false,
                region: "right"
            },
            "results_pane"
            );
 


            
            var bottom_pane = new dijit.layout.ContentPane({
                splitter: false,
                region: "bottom"
            },
            "footer_pane"
            );

            //Tree-generating code          
            var dataStore = new dojo.data.ItemFileReadStore({
                data: facet_object
            });

            var model = new dijit.tree.ForestStoreModel({
                store: dataStore,
                query: {
                    "type": "*"
                }
            });

            new dijit.Tree({
                model: model,
                showRoot: false,
                persist: false,
                onClick: function(item,label) { window.location = dataStore.getValue(item,"url") }
            },
            "facet_tree");
                      
            border_container.startup();
            border_container.addChild(results_pane);
            border_container.addChild(document_pane);
            border_container.addChild(top_pane);
            border_container.addChild(bottom_pane);
            border_container.addChild(left_pane);

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
