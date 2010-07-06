//Scripts to load Dojo forms

//First load the necessary Dojo modules
dojo.require("dijit.Toolbar");
dojo.require("dijit.form.Button");
dojo.require("dijit.TooltipDialog");
dojo.require("dijit.Menu");
dojo.require("dijit.form.TextBox");
dojo.require("dijit.form.NumberTextBox");
    
//Toolbar

       var any_language     = 0;
       var include_language = 0;
       var any_medium       = 0;
       var include_medium   = 0;

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
