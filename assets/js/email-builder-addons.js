
let
  emailbuilderLoadedJSON = null;


const emailbuilderAddonClearJSON = {
  "root": {
    "type": "EmailLayout",
    "data": {
      "backdropColor": "#F5F5F5",
      "canvasColor": "#FFFFFF",
      "textColor": "#262626",
      "fontFamily": "MODERN_SANS",
      "childrenIds": []
    }
  }
};


function emailbuilderAddonSavebtn() {
  setTimeout(() => {
    const ribbon = dqsA(".MuiStack-root.css-jj2ztu");
    if (ribbon.length < 2) {
      return;
    }
    if (dqs("#saveButton")) {
      return;
    }
    const saveButton = jsRender(jsCreateElement("button", {
      attrs: {
        class: "MuiButtonBase-root MuiButton-root MuiButton-contained MuiButton-containedPrimary",
        id: "saveButton",
        style: "padding: 4px 40px;",
        onclick: "saveMail(" + globalMailData.id + ")"
      },
      children: ["Save"]
    }));
    ribbon[1].prepend(saveButton);


    const closeButton = jsRender(jsCreateElement("button", {
      attrs: {
        class: "MuiButtonBase-root MuiButton-root MuiButton-contained MuiButton-containedPrimary",
        id: "closeButton",
        style: "padding: 4px 40px;",
        onclick: "emailbuilderCloseModal();"
      },
      children: ["Close"]
    }));
    ribbon[1].prepend(closeButton);

  }, 1000);
}


function emailbuilderAddonSetJson(jsonData) {
  try {
    const parsedData = JSON.parse(jsonData);
    Fg(parsedData);
  } catch (error) {
    console.error("Invalid JSON data:", error);
  }
}


function emailbuilderAddonGetJson() {
  const jsonButton = dqs(".MuiButtonBase-root.MuiIconButton-root.MuiIconButton-sizeMedium.css-17kijze[download='emailTemplate.json']");

  // get the JSON. its data:text/plain in the href
  let jsonOutput = "";
  if (jsonButton) {
    const dataUrl = jsonButton.href;
    const base64Data = dataUrl.split(",")[1];
    jsonOutput = decodeURIComponent(base64Data);
  }
  //console.log(jsonOutput);
  dqs(".modalpop").classList.remove("hasjson");
  return jsonOutput;
}


function emailbuilderAddonGetHTML() {
  let jsonStructure = JSON.parse(emailbuilderAddonGetJson());
  let html = emailbuilderInternalHTMLBody(jsonStructure, { rootBlockId: 'root' });
  //let rawHtml = html.replace(/&quot;/g, '"');
  return html;
}


function emailbuilderInternalHTMLBody(e, {
  rootBlockId: t
}) {
  return Vde(R.createElement(W6, {
    document: e,
    rootBlockId: t
  }))
}


function emailbuilderInternalHTMLFull(e, {
  rootBlockId: t
}) {
  return "<!DOCTYPE html>" + Vde(R.createElement("html", null, R.createElement("body", null, R.createElement(W6, {
    document: e,
    rootBlockId: t
  }))))
}


function emailbuilderCloseModal() {
  if ( JSON.stringify(emailbuilderLoadedJSON) !== JSON.stringify(emailbuilderAddonGetJson()) ) {
    if (confirm("You have unsaved changes. Quit?")) {
      dqs(".modalpop").classList.remove("show");
    }
  } else {
    dqs(".modalpop").classList.remove("show");
  }
}

/*

let jsonStructure = JSON.parse(emailbuilderAddonGetJson());
let html = fpe(jsonStructure, { rootBlockId: 'root' });
let rawHtml = html.replace(/&quot;/g, '"');

console.log(rawHtml); // Outputs raw HTML with real quotes

// Return formatted HTML for preview in a PRE
_1e(emailbuilderAddonGetJson())
.then(r => {
    console.log(r)
})

// Return JSON but formatted like &quot;
g1e(emailbuilderAddonGetJson())
.then(r => {
    console.log(r)
})

*/

