window.addEventListener("DOMContentLoaded", (event) => {
  function checkUrlPath() {
    const path = window.location.pathname;

    if (window.location.href.includes("#")) {
      return;
    }

    switch (path) {
      case '/contacts':
        tableContacts();
        break;
      case '/mails':
        tableMails();
        break;
      case '/lists':
        tableLists();
        break;
      case '/flows':
        tableFlows();
        break;
      case '/maillog':
        tableMaillog();
        break;
      case '/settings':
        buildSettingsHtml();
        break;
      // default:
      //   dqs("#heading").innerText = "Nimletter, drip it!";
      //   dqs("#work").innerHTML = '<img src="/assets/images/nimletter.png">';
    }
  }

  window.addEventListener("popstate", checkUrlPath);

  checkUrlPath();
});


function addNewButton(eleID, onclick, text) {
  return `
    <button onclick="${onclick}" style="display: flex ; align-items: center;width: 200px; justify-content: center;">
      <svg style="height:24px; width: 24px;" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v6m3-3H9m12 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" /></svg>
      <div style="margin-left: 5px;">${text}</div>
    </button>
    <div id="${eleID}"></div>
  `;
}


/*

  Contacts

*/
let objTableContacts;
function tableContacts() {
  dqs("#heading").innerText = "Contacts";
  dqs("#work").innerHTML = addNewButton("contacts", "addContact()", "Add contact");

  objTableContacts = new Tabulator("#contacts", {
    height:"70vh",
    layout:"fitColumns",
    ajaxURL:"/api/contacts/all",
    progressiveLoad:"load",
    rowFormatter:function(row){
      var data = row.getData();

      // If bounced_at then extreme red, if complained_at then extreme orange
      if(data.bounced_at){
      row.getElement().style.backgroundColor = "#FF0000";
      } else if(data.complained_at){
      row.getElement().style.backgroundColor = "#FFA500";
      } else if(data.emails_count_sent >= 2 && data.emails_count_open <= 0){
      row.getElement().style.backgroundColor = "#fff9bf8f";
    }

    },
    columns:[
      {title:"ID", field:"id", width:50, headerFilter:true},
      {title:"Email", field:"email", width:250, headerFilter:true},
      {title:"Name", field:"name", width:200, headerFilter:true},
      {title:"Requires Double Opt-In", field:"requires_double_opt_in", hozAlign:"center", width: 80, headerFilter:true, formatter:"toggle", formatterParams:{
        size:16,
        onValue:"on",
        offValue:"off",
        onTruthy:true,
        onColor:"var(--colorG200)",
        offColor:"var(--colorN80)",
        clickable:false,
      }},
      {title:"Double Opt-In", field:"double_opt_in", hozAlign:"center", width: 80, headerFilter:true, formatter:"toggle", formatterParams:{
        size:16,
        onValue:"on",
        offValue:"off",
        onTruthy:true,
        onColor:"var(--colorG200)",
        offColor:"var(--colorN80)",
        clickable:false,
      }},

      {title:"Country", field:"country", hozAlign:"left", width: 140, headerFilter:true},

      // Lists
      {title:"Lists", field:"subscribed_lists", hozAlign:"left", width: 200, headerFilter:true, formatter:function(cell, formatterParams, onRendered){
      if (cell.getValue() == "") {
        return "";
      }

      let lists = cell.getValue().split(", ");
      let html = "";
      lists.forEach(list => {
        html += `<div style="font-size: 12px; border: 1px solid var(--colorN100); border-radius: 10px; padding: 0px 6px; background-color: var(--colorN20); margin-right: 5px;">${list}</div>`;
      });
      return '<div style="display: flex">' + html + '</div>';
      }},

      {title:"Opening Rate", field:"opening_rate", hozAlign:"center", width: 140, headerFilter:true, formatter:function(cell, formatterParams, onRendered){
      let
        rowData = cell.getRow().getData(),
        sent = rowData.emails_count_sent,
        open = rowData.emails_count_open;

      return sent > 0 ? Math.round((open / sent) * 100) + "%" : "0%";
      }
      },
      {title:"Emails Open", field:"emails_count_open", hozAlign:"center", width: 140, headerFilter:true},
      {title:"Emails Clicks", field:"emails_count_clicks", hozAlign:"center", width: 140, headerFilter:true},
      {title:"Emails Sent", field:"emails_count_sent", hozAlign:"center", width: 140, headerFilter:true},
      {title:"Emails Pending", field:"emails_count_pending", hozAlign:"center", width: 140, headerFilter:true},

      {title:"Bounced At", field:"bounced_at", hozAlign:"center", sorter:"date", width: 140, headerFilter:true},
      {title:"Complained At", field:"complained_at", hozAlign:"center", sorter:"date", width: 140, headerFilter:true},
      {title:"Created At", field:"created_at", hozAlign:"center", sorter:"date", width: 160, headerFilter:true},
      {title:"Updated At", field:"updated_at", hozAlign:"center", sorter:"date", width: 160, headerFilter:true},
    ],
    });

  objTableContacts.on("rowClick", function(e, row){
    loadContact(row.getData().id);
  });

}


/*

  Mails

*/
var objTableMails;
function tableMails() {
  dqs("#heading").innerText = "Mails";
  dqs("#work").innerHTML = addNewButton("mails", "addMail()", "Add mail");

  objTableMails = new Tabulator("#mails", {
    height:"70vh",
    layout:"fitColumns",
    ajaxURL:"/api/mails/all",
    progressiveLoad:"load",
    initialSort:[
      {column:"name", dir:"asc"}
    ],
    // rowHeight:50,
    columns:[
      {title:"ID", field:"id", vertAlign: "middle", width:60, headerFilter:true},
      {title:"Name", field:"name", vertAlign: "middle", minWidth:200, headerFilter:true},
      {title:"Subject", field:"subject", vertAlign: "middle", minWidth:250, headerFilter:true},
      {title:"Identifier", field:"identifier", vertAlign: "middle", width:140, headerFilter:true},
      {title:"Category", field:"category", vertAlign: "middle", width:200, headerFilter:true},
      {title:"Tags", field:"tags", vertAlign: "middle", width:200, headerFilter:true, formatter:function(cell, formatterParams, onRendered){
        if (cell.getValue() == "") {
          return "";
        }
        let tags = cell.getValue();
        let html = "";
        tags.forEach(list => {
          html += `<div style="font-size: 12px; border: 1px solid var(--colorN100); border-radius: 10px; padding: 0px 6px; background-color: var(--colorN20); margin-right: 5px;">${list}</div>`;
        });
        return '<div style="display: flex">' + html + '</div>';
      }},
      {title:"Sent count", field:"sent_count", vertAlign: "middle", width:120, headerFilter:true},
      {title:"Pending count", field:"pending_count", vertAlign: "middle", width:120, headerFilter:true},
      {title:"Created At", field:"created_at", vertAlign: "middle", hozAlign:"center", sorter:"date", width: 160, headerFilter:true},
      {title:"Updated At", field:"updated_at", vertAlign: "middle", hozAlign:"center", sorter:"date", width: 160, headerFilter:true},
    ],
  });

  objTableMails.on("rowClick", function(e, row){
    loadMail(row.getData().id);
  });
}


/*

  Lists

*/
let objTableLists;
function tableLists() {
  dqs("#heading").innerText = "Lists";
  dqs("#work").innerHTML = addNewButton("lists", "addList()", "Add list");

  objTableLists = new Tabulator("#lists", {
    height:"70vh",
    layout:"fitColumns",
    ajaxURL:"/api/lists/all",
    progressiveLoad:"load",
    // rowHeight:50,
    columns:[
      {title:"ID", field:"id", width:100, headerFilter:true},
      // {title:"UUID", field:"uuid", width:200},
      {title:"Name", field:"name", vertAlign: "middle", width:200, headerFilter:true},
      {title:"Description", field:"description", vertAlign: "middle", width:250, headerFilter:true},
      // {title:"Flow ID", field:"flow_id", vertAlign: "middle", width:200},
      {title:"Identifier", field:"identifier", vertAlign: "middle", width:200, headerFilter:true},
      {title:"Contacts", field:"user_count", vertAlign: "middle", width:200, headerFilter:true, formatter:function(cell, formatterParams, onRendered){
      return cell.getValue() + ' subscribers';
      }},
      {title:"Flow Count", field:"flows", vertAlign: "middle", width:200, headerFilter:true},
      {title:"Created At", field:"created_at", vertAlign: "middle", hozAlign:"center", sorter:"date", width: 200, headerFilter:true},
      {title:"Updated At", field:"updated_at", vertAlign: "middle", hozAlign:"center", sorter:"date", width: 200, headerFilter:true},
      {title:"Delete", formatter:function(cell, formatterParams, onRendered){
      return '<button onclick="removeList(' + cell.getRow().getData().id + ')">Delete</button>';
      }},
    ],
  });

  objTableLists.on("rowClick", function(e, row){
    openList(row.getData().id);
  });
}


/*

  Flows

*/
let objTableFlows;
function tableFlows() {
  dqs("#heading").innerText = "Flows";
  dqs("#work").innerHTML = addNewButton("flows", "addFlow()", "Add flow");

  objTableFlows = new Tabulator("#flows", {
    height:"70vh",
    layout:"fitColumns",
    ajaxURL:"/api/flows/all",
    progressiveLoad:"load",
    columns:[
      {title:"ID", field:"id", width:100, headerFilter:true},
      // {title:"UUID", field:"uuid", width:200},
      {title:"Name", field:"name", width:200, headerFilter:true},
      {title:"Description", field:"description", width:250, headerFilter:true},
      {title:"Opening Rate", field:"opening_rate", width:150, headerFilter:true},
      {title:"Pending Count", field:"pending_count", width:150, headerFilter:true},
      {title:"Sent Count", field:"sent_count", width:150, headerFilter:true},
      {title:"Created At", field:"created_at", hozAlign:"center", sorter:"date", width: 200, headerFilter:true},
      {title:"Updated At", field:"updated_at", hozAlign:"center", sorter:"date", width: 200, headerFilter:true},
      {title:"Delete", formatter:function(cell, formatterParams, onRendered){
      return '<button onclick="removeFlow(' + cell.getRow().getData().id + ')">Delete</button>';
      }},
    ],
  });

  objTableFlows.on("rowClick", function(e, row){
    openFlow(row.getData().id);
  });
}


/*

  Flowsteps

*/
function tableFlowsteps(flowID) {
  dqs("#work").innerHTML = `
    <div id="flowsteps"></div>
  `;

  var objTableFlowsteps = new Tabulator("#flowsteps", {
    height:"70vh",
    layout:"fitColumns",
    ajaxURL:"/api/flowsteps/all?flowID=" + flowID,
    progressiveLoad:"load",
    columns:[
      {title:"ID", field:"id", width:100},
      {title:"Flow ID", field:"flow_id", width:200},
      {title:"Mail ID", field:"mail_id", width:200},
      {title:"Step Number", field:"step_number", width:150},
      {title:"Delay Minutes", field:"delay_minutes", width:150},
      {title:"Subject", field:"subject", width:250},
      {title:"Created At", field:"created_at", hozAlign:"center", sorter:"date", width: 200},
      {title:"Updated At", field:"updated_at", hozAlign:"center", sorter:"date", width: 200},
    ],
  });
}



/*

  Maillog

*/
let objTableMaillog;
function tableMaillog() {
  dqs("#heading").innerText = "Maillog";
  dqs("#work").innerHTML = addNewButton("maillog", "addMaillog()", "Add maillog");

  objTableMaillog = new Tabulator("#maillog", {
    height:"70vh",
    layout:"fitColumns",
    ajaxURL:"/api/mails/log",
    progressiveLoad:"scroll",
    columns:[
      {title:"ID", field:"id", width:80},
      {title:"Sent At", field:"sent_at", width:140, sorter:"date", headerFilter:true},
      {title:"Opened", field:"opened", width:90, headerFilter:true},
      {title:"Clicked", field:"clicked", width:90, headerFilter:true},
      {title:"User Email", field:"user_email", minWidth:200, headerFilter:true},
      {title:"Country", field:"country", width:160, headerFilter:true},
      {title:"List Name", field:"list_name", minWidth:160, headerFilter:true},
      {title:"Flow Name", field:"flow_name", minWidth:160, headerFilter:true},
      {title:"Flow Step Name", field:"flow_step_name", width:160, headerFilter:true},
      {title:"Created At", field:"created_at", hozAlign:"center", sorter:"date", width: 140, headerFilter:true},
    ],
    });
}