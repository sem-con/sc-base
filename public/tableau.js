(function () {
    var myConnector = tableau.makeConnector();

    myConnector.getSchema = function (schemaCallback) {
        var args = JSON.parse(tableau.connectionData);
        eval(args.schema);
        schemaCallback([tableSchema]);
    };

    myConnector.getData = function (table, doneCallback) {
        var args = JSON.parse(tableau.connectionData);

        const apiUrl=args.url;
        const getRecs = async function(pageNo = 1) {

          let actualUrl=apiUrl + `&page=${pageNo}`;
          var apiResults=await fetch(actualUrl)
          .then(resp=>{
                return resp.json();
          });

          return apiResults;

        }

        const getEntireRecs = async function(pageNo = 1) {
          const results = await getRecs(pageNo);
          console.log("Retreiving data from API for page : " + pageNo);
          if (results.length>0) {
            return results.concat(await getEntireRecs(pageNo+1));
          } else {
            return results;
          }
        };


        (async ()=>{

            const row=await getEntireRecs();
            var tableData = [];

            // Iterate over the JSON object
            for (var i = 0, len = row.length; i < len; i++) {
                eval(args.tabledata);
            }

            table.appendRows(tableData);
            doneCallback();

        })();
    };

    tableau.registerConnector(myConnector);
    $(document).ready(function () {
        $("#submitButton").click(function () {
            var argObj = {
               schema: $('#schema').val().trim(),
               url: $('#url').val().trim(),
               tabledata: $('#tabledata').val().trim(),
            };
            tableau.connectionData = JSON.stringify(argObj);
            tableau.connectionName = "Semantic Container Feed";
            tableau.submit();
        });
    });
})();
