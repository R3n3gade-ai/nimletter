

let
  globalListID,
  globalListFlowIDs = [];

// -- Create
async function addList() {
  const html = jsCreateElement('div', {
    attrs: {
      style: "width: 300px;"
    },
    children: [
      jsCreateElement('div', {
        attrs: {
          class: 'headingH3 mb20 center'
        },
        children: ['Add list']
      }),
      jsCreateElement('div', {
        attrs: {
          class: 'itemBlock mb20'
        },
        children: [
          jsCreateElement('label', {
            attrs: {
              class: 'forinput active'
            },
            children: ['List name']
          }),
          jsCreateElement('input', {
            attrs: {
              type: 'text',
              id: 'listNewName'
            }
          })
        ]
      }),
      jsCreateElement('div', {
        attrs: {
          class: 'itemBlock mb20'
        },
        children: [
          jsCreateElement('label', {
            attrs: {
              class: 'forinput'
            },
            children: ['Description']
          }),
          jsCreateElement('input', {
            attrs: {
              type: 'text',
              id: 'listNewDescription'
            }
          })
        ]
      }),
      jsCreateElement('div', {
        attrs: {
          style: "font-size: 12px;margin:20px;"
        },
        children: [
          'A list used to group contacts. The name of the list is used to identify it. E.g. "Weekly newsletter", "Marketing list", "Drip sign up", etc.'
        ]
      }),
      jsCreateElement('div', {
        children: [
          jsCreateElement('button', {
            attrs: {
              class: 'svg30 w100p',
              onclick: 'addListDo()'
            },
            rawHtml: [
              '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v6m3-3H9m12 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" /></svg><div style="margin-left: 5px;">Add list</div>'
            ]
          })
        ]
      })
    ]
  });
  rawModalLoader(jsRender(html));
  labelFloater();
  setTimeout(() => {
    dqs("#listNewName").focus();
  }, 100);
}

function addListDo() {
  let
    name = dqs("#listNewName").value,
    description = dqs("#listNewDescription").value;

  fetch("/api/lists/create", {
    method: "POST",
    body: new URLSearchParams({
      name: name,
      description: description,
    })
  })
  .then(manageErrors)
  .then(() => {
    dqs(".modalpop").remove();
    objTableLists.setData();
  });

}




// -- Remove
function removeList(listID) {
  const html = jsCreateElement('div', {
    attrs: {
      style: "width: 300px;"
    },
    children: [
      jsCreateElement('div', {
        attrs: {
          class: 'headingH3 mb20 center'
        },
        children: ['Remove list']
      }),
      jsCreateElement('div', {
        attrs: {
          style: "font-size: 12px;margin:20px;"
        },
        children: [
          'Are you sure you want to remove this list?'
        ]
      }),
      jsCreateElement('div', {
        children: [
          jsCreateElement('button', {
            attrs: {
              class: 'svg30 w100p',
              onclick: 'removeListDo(' + listID + ')'
            },
            rawHtml: [
              '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0"></path></svg><div style="margin-left: 5px;">Remove</div>'
            ]
          })
        ]
      })
    ]
  });
  rawModalLoader(jsRender(html));
}

function removeListDo(listID) {
  fetch("/api/lists/delete?listID=" + listID, {
    method: "DELETE",
  })
  .then(manageErrors)
  .then(() => {
    dqs(".modalpop").remove();
    objTableLists.setData();
  });
}



// -- Open list

function openList(listID) {
  globalListID = listID;
  fetch("/api/lists/get?listID=" + listID)
    .then(response => response.json())
    .then(data => {
      let locked = data.identifier == 'default';
      data.flow_id.forEach(flow => {
        globalListFlowIDs.push(flow.id);
      });

      const html = jsCreateElement('div', {
        attrs: {
          style: "width: 300px;"
        },
        children: [
          jsCreateElement('div', {
            attrs: {
              class: 'headingH3 mb20 center'
            },
            children: ['Edit list']
          }),
          jsCreateElement('div', {
            attrs: {
              class: 'itemBlock mb20'
            },
            children: [
              jsCreateElement('label', {
                attrs: {
                  class: 'forinput active'
                },
                children: ['List name']
              }),
              jsCreateElement('input', {
                attrs: {
                  type: 'text',
                  id: 'listEditName',
                  value: data.name
                }
              })
            ]
          }),
          jsCreateElement('div', {
            attrs: {
              class: 'itemBlock mb20'
            },
            children: [
              jsCreateElement('label', {
                attrs: {
                  class: 'forinput'
                },
                children: ['Description']
              }),
              jsCreateElement('input', {
                attrs: {
                  type: 'text',
                  id: 'listEditDescription',
                  value: data.description
                }
              })
            ]
          }),
          jsCreateElement('div', {
            attrs: {
              class: 'itemBlock mb20'
            },
            children: [
              jsCreateElement('label', {
                attrs: {
                  class: 'forinput'
                },
                children: ['Identifier']
              }),
              jsCreateElement('input', {
                attrs: {
                  id: 'listEditIdentifier',
                  type: 'text',
                  value: data.identifier,
                }
              })
            ]
          }),
          // The next is the link - current window.location.origin + /subscribe/ + data.uuid
          jsCreateElement('div', {
            attrs: {
              class: 'itemBlock mb20'
            },
            children: [
              jsCreateElement('label', {
                attrs: {
                  class: 'forinput'
                },
                children: ['Subscribe link']
              }),
              jsCreateElement('input', {
                attrs: {
                  type: 'text',
                  value: window.location.origin + '/subscribe/' + data.uuid,
                  readonly: true
                }
              })
            ]
          }),
          jsCreateElement('div', {
            attrs: {
              class: 'itemBlock mb20'
            },
            children: data.flow_id.map(flow => 
              jsCreateElement('div', {
                attrs: {
                  class: 'flowItem',
                  style: 'display: grid ; grid-template-columns: 1fr 50px; align-items: center; border: 1px solid var(--colorN40); background-color: var(--colorN20); padding: 10px;'
                },
                children: [
                  jsCreateElement('span', {
                    children: [flow.name]
                  }),
                  jsCreateElement('button', {
                    attrs: {
                      class: 'svg16',
                      onclick: `removeFlow(${flow.id})`
                    },
                    rawHtml: [
                      '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/></svg>'
                    ]
                  })
                ]
              })
            )
          }),
          jsCreateElement('div', {
            children: [
              jsCreateElement('button', {
                attrs: {
                  class: 'buttonIcon mb20',
                  onclick: 'addFlowToList()'
                },
                rawHtml: [
                  '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v6m3-3H9m12 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" /></svg><div style="margin-left: 5px;">Add flow</div>'
                ]
              })
            ]
          }),
          jsCreateElement('div', {
            children: [
              jsCreateElement('button', {
                attrs: {
                  class: 'buttonIcon' + (locked ? ' disabled' : ''),
                  onclick: `updateList(${listID})`
                },
                rawHtml: [
                  '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg><div style="margin-left: 5px;">Save changes</div>'
                ]
              })
            ]
          })
        ]
      });
      rawModalLoader(jsRender(html));
      labelFloater();
    });
}

function updateList(listID) {
  let
    name = dqs("#listEditName").value,
    description = dqs("#listEditDescription").value,
    identifier = dqs("#listEditIdentifier").value;

  fetch("/api/lists/update", {
    method: "POST",
    body: new URLSearchParams({
      listID: listID,
      name: name,
      description: description,
      identifier: identifier
    })
  })
  .then(manageErrors)
  .then(() => {
    dqs(".modalpop").remove();
    objTableLists.setData();
  });
}

function removeFlow(flowID) {
  const html = jsCreateElement('div', {
    attrs: {
      style: "width: 300px;"
    },
    children: [
      jsCreateElement('div', {
        attrs: {
          class: 'headingH3 mb20 center'
        },
        children: ['Remove flow']
      }),
      jsCreateElement('div', {
        attrs: {
          style: "font-size: 12px;margin:20px;"
        },
        children: [
          'Are you sure you want to remove this flow from the list?'
        ]
      }),
      jsCreateElement('div', {
        children: [
          jsCreateElement('button', {
            attrs: {
              class: 'buttonIcon',
              onclick: 'removeFlowDo(' + flowID + ')'
            },
            rawHtml: [
              '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m-12 .562a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0"></path></svg><div style="margin-left: 5px;">Remove</div>'
            ]
          })
        ]
      })
    ]
  });
  rawModalLoader(jsRender(html));
}

function removeFlowDo(flowID) {
  // Implement the function to remove a flow from the list
  fetch("/api/lists/flow/remove", {
    method: "POST",
    body: new URLSearchParams({
      listID: globalListID,
      flowID: flowID,
    })
  });
}

function addFlowToList() {

  fetch("/api/flows/all")
    .then(response => response.json())
    .then(data => {
      const html = jsCreateElement('div', {
        attrs: {
          style: "width: 300px;"
        },
        children: [
          jsCreateElement('div', {
            attrs: {
              class: 'headingH3 mb20 center'
            },
            children: ['Add flow']
          }),
          jsCreateElement('div', {
            attrs: {
              class: 'itemBlock mb20'
            },
            children: [
              jsCreateElement('label', {
                attrs: {
                  class: 'forinput active'
                },
                children: ['Select flow']
              }),
              jsCreateElement('select', {
                attrs: {
                  id: 'flowSelect'
                },
                children: (data.data).map(flow =>
                  jsCreateElement('option', {
                    attrs: {
                      value: flow.id,
                      disabled: globalListFlowIDs.includes(flow.id) ? 'disabled' : false
                    },
                    children: [flow.name]
                  })
                )
              })
            ]
          }),
          jsCreateElement('div', {
            children: [
              jsCreateElement('p', {
                attrs: {
                  style: "font-size: 12px;margin:20px;"
                },
                children: [
                  'The flow will be startet for all contacts in the list.'
                ]
              })
            ]
          }),
          jsCreateElement('div', {
            children: [
              jsCreateElement('button', {
                attrs: {
                  class: 'svg30 w100p',
                  onclick: 'addFlowToListDo()'
                },
                rawHtml: [
                  '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v6m3-3H9m12 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" /></svg><div style="margin-left: 5px;">Add flow</div>'
                ]
              })
            ]
          })
        ]
      });
      rawModalLoader(jsRender(html));
    });
}

function addFlowToListDo() {
  let
    flowID = dqs("#flowSelect").value;

  fetch("/api/lists/flow/add", {
    method: "POST",
    body: new URLSearchParams({
      listID: globalListID,
      flowID: flowID,
    })
  })
  .then(manageErrors)
  .then(() => {
    dqs(".modalpop").remove();
    objTableLists.setData();
  });
}
