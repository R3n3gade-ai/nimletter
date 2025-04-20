let
  globalFlowID,
  globalFlowStepsData = [];


// -- Add flow
function addFlow() {
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
              class: 'forinput'
            },
            children: ['Flow name']
          }),
          jsCreateElement('input', {
            attrs: {
              type: 'text',
              id: 'flowNewName'
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
              id: 'flowNewDescription'
            }
          })
        ]
      }),
      jsCreateElement('div', {
        attrs: {
          style: "font-size: 12px;margin:20px;"
        },
        children: [
          'A flow is a sequence of emails that are sent to a list of contacts. It can be single email, or a full drip campaign. You need a flow to assign to a list.'
        ]
      }),
      jsCreateElement('div', {
        children: [
          jsCreateElement('button', {
            attrs: {
              class: 'svg30 w100p',
              onclick: 'addFlowDo()'
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
  setTimeout(() => {
    dqs("#flowNewName").focus();
    labelFloater();
  }, 100);
}

function addFlowDo() {
  let
    name = dqs("#flowNewName").value,
    description = dqs("#flowNewDescription").value;

  fetch("/api/flows/create", {
    method: "POST",
    body: new URLSearchParams({
      name: name,
      description: description,
    })
  })
  .then(manageErrors)
  .then(response => response.json())
  .then(data => {
    dqs(".modalpop").remove();
    openFlow(data.id);
  });

}



// -- Remove
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
          'Are you sure you want to remove this flow?'
        ]
      }),
      jsCreateElement('div', {
        children: [
          jsCreateElement('button', {
            attrs: {
              class: 'svg30 w100p',
              onclick: 'removeFlowDo(' + flowID + ')'
            },
            rawHtml: [
              '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v6m3-3H9m12 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" /></svg><div style="margin-left: 5px;">Remove flow</div>'
            ]
          })
        ]
      })
    ]
  });
  rawModalLoader(jsRender(html));
  setTimeout(() => {
    dqs("#flowRemoveID").focus();
    labelFloater();
  }, 100);
}

function removeFlowDo(flowID) {

  fetch("/api/flows/delete?flowID=" + flowID, {
    method: "DELETE"
  })
  .then(manageErrors)
  .then(() => {
    dqs(".modalpop").remove();
    objTableFlows.setData();
  });
}




// -- Open flow
function openFlow(flowID) {
  globalFlowID = flowID;

  fetch("/api/flow_steps/all?flowID=" + flowID, {
    method: "GET"
  })
  .then(manageErrors)
  .then(response => response.json())
  .then(data => {
    console.log(data);
    globalFlowStepsData = data;
    buildFlowHTML(data);
  });
}


async function buildFlowHTML(data) {

  let mails = await fetch("/api/mails/all")
  .then(response => response.json())
  .then(data => data.data);



  let flowSteps = [];
  data.forEach(step => {


    //
    // Mail options
    let mailsOpts = [];
    mailsOpts.push(jsCreateElement('option', {
      attrs: {
        value: ''
      },
      children: ['I\'ll select a mail later']
    }));
    for (let i = 0; i < mails.length; i++) {
      mailsOpts.push(jsCreateElement('option', {
        attrs: {
          value: mails[i].id,
          selected: (step.mail_id == mails[i].id) ? "selected" : false
        },
        children: [mails[i].name]
      }));
    }


    //
    // Trigger options
    let triggerOpts = [];
    triggerOpts.push(jsCreateElement('option', {
      attrs: {
        value: 'delay',
        selected: (step.trigger_type == 'delay') ? "selected" : false
      },
      children: ['Delay']
    }));
    triggerOpts.push(jsCreateElement('option', {
      attrs: {
        value: 'open',
        selected: (step.trigger_type == 'open') ? "selected" : false
      },
      children: ['Open previous mail']
    }));
    triggerOpts.push(jsCreateElement('option', {
      attrs: {
        value: 'click',
        selected: (step.trigger_type == 'click') ? "selected" : false
      },
      children: ['Click link in previous mail']
    }));
    triggerOpts.push(jsCreateElement('option', {
      attrs: {
        value: 'time',
        selected: (step.trigger_type == 'time') ? "selected" : false
      },
      children: ['Specific time']
    }));


    //
    // Build step
    flowSteps.push(jsCreateElement('div', {
      attrs: {
        class: 'itemBlock mb20 stepBlock'
      },
      children: [
        jsCreateElement('div', {
          attrs: {
            class: '',
            style: 'font-weight: 500; font-size: 20px;'
          },
          children: ['Step ' + step.step_number]
        }),
        jsCreateElement('div', {
          attrs: {
            class: 'stepInfo',
            style: 'display: grid ; grid-template-columns: 1fr 150px; grid-gap: 20px; align-items: center;'
          },
          children: [
            jsCreateElement('div', {
              attrs: {
                class: 'stepInfoItems'
              },
              children: [
                jsCreateElement('button', {
                  attrs: {
                    style: 'position: absolute; top: -18px; right: 12px; display: flex ; align-items: center; justify-content: center; width: 40px; height: 34px;',
                    onclick: "settingsFlowStep(" + step.id + ")"
                  },
                  rawHtml: [
                    '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.325.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 0 1 1.37.49l1.296 2.247a1.125 1.125 0 0 1-.26 1.431l-1.003.827c-.293.241-.438.613-.43.992a7.723 7.723 0 0 1 0 .255c-.008.378.137.75.43.991l1.004.827c.424.35.534.955.26 1.43l-1.298 2.247a1.125 1.125 0 0 1-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.47 6.47 0 0 1-.22.128c-.331.183-.581.495-.644.869l-.213 1.281c-.09.543-.56.94-1.11.94h-2.594c-.55 0-1.019-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 0 1-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 0 1-1.369-.49l-1.297-2.247a1.125 1.125 0 0 1 .26-1.431l1.004-.827c.292-.24.437-.613.43-.991a6.932 6.932 0 0 1 0-.255c.007-.38-.138-.751-.43-.992l-1.004-.827a1.125 1.125 0 0 1-.26-1.43l1.297-2.247a1.125 1.125 0 0 1 1.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.086.22-.128.332-.183.582-.495.644-.869l.214-1.28Z" /><path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" /></svg>'
                  ]
                }),
                // Name
                jsCreateElement('label', {
                  attrs: {
                    class: 'labelBold'
                  },
                  children: ['Flow name']
                }),
                jsCreateElement('input', {
                  attrs: {
                    id: "flowStepName_" + step.id,
                    value: step.name,
                  },
                }),
                // Mail
                jsCreateElement('label', {
                  attrs: {
                    class: 'labelBold'
                  },
                  children: ['Mail']
                }),
                jsCreateElement('select', {
                  attrs: {
                    id: "flowStepMail_" + step.id,
                  },
                  children: mailsOpts
                }),
                // Subject
                jsCreateElement('label', {
                  attrs: {
                    class: 'labelBold'
                  },
                  children: ['Mail subject']
                }),
                jsCreateElement('input', {
                  attrs: {
                    id: "flowStepSubject_" + step.id,
                    value: step.subject,
                  },
                }),
                // Trigger
                jsCreateElement('div', {
                  attrs: {
                    style: 'display: grid; grid-template-columns: 1fr 1fr; grid-gap: 20px;'
                  },
                  children: [
                    jsCreateElement('div', {
                      children: [
                        jsCreateElement('label', {
                          attrs: {
                            class: 'labelBold'
                          },
                          children: ['Trigger']
                        }),
                        jsCreateElement('select', {
                          attrs: {
                            id: "flowStepTrigger_" + step.id,
                          },
                          children: triggerOpts
                        })
                      ]
                    }),
                    jsCreateElement('div', {
                      children: [
                        jsCreateElement('label', {
                          attrs: {
                            class: 'labelBold'
                          },
                          children: ['Delay minutes']
                        }),
                        jsCreateElement('input', {
                          attrs: {
                            id: "flowStepDelay_" + step.id,
                            value: step.delay_minutes,
                            style: step.trigger_type == 'time' ? 'display: none;' : ''
                          },
                        }),
                        jsCreateElement('input', {
                          attrs: {
                            id: "flowStepTime_" + step.id,
                            type: 'time',
                            value: step.scheduled_time || '',
                            style: step.trigger_type == 'time' ? '' : 'display: none;'
                          },
                        })
                      ]
                    })
                  ]
                })
              ]
            }),
            jsCreateElement('div', {
              attrs: {
                class: 'stepInfoStats center',
                style: 'cursor: pointer;',
                onclick: 'openStepStats(' + step.id + ')'
              },
              rawHtml: [
                'Currently this mail has been <br><b>sent to ' + step.sent_count.toString() + '</b><br> contacts. There are <br><b>pending ' + step.pending_count.toString() + '</b><br> mails for this step due to the trigger.'
              ]
            })
          ]
        })
      ]
    }));
  });

  const html = jsCreateElement('div', {
    children: [
      jsCreateElement('div', {
      }),
      jsCreateElement('div', {
        children: flowSteps
      }),
      jsCreateElement('button', {
        attrs: {
          class: 'buttonIcon',
          onclick: 'addFlowStep()',
          style: 'width: 540px; height: 60px;'
        },
        rawHtml: [
          '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v6m3-3H9m12 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" /></svg><div style="margin-left: 5px;">Add step</div>'
        ]
      }),
    ]
  });


  dqs("#work").innerHTML = "";
  dqs("#work").appendChild(jsRender(html));

  // On changes in input and select call: updateFlowStep
  let inputs = document.querySelectorAll("input, select");
  for (let i = 0; i < inputs.length; i++) {
    inputs[i].addEventListener("change", function() {
      // Check if this is a trigger type selection
      if (this.id.startsWith("flowStepTrigger_")) {
        const stepId = this.id.split("_")[1];
        // Show/hide time or delay input based on trigger type
        if (this.value === "time") {
          document.getElementById("flowStepTime_" + stepId).style.display = "";
          document.getElementById("flowStepDelay_" + stepId).style.display = "none";
        } else {
          document.getElementById("flowStepTime_" + stepId).style.display = "none";
          document.getElementById("flowStepDelay_" + stepId).style.display = "";
        }
      }
      
      // Call updateFlowStep for all changes
      updateFlowStep(this.id.split("_")[1]);
    });
  }

}


// -- Add flow
async function addFlowStep() {
  
  let mails = await fetch("/api/mails/all")
  .then(response => response.json())
  .then(data => data.data);

  // Mail options
  let mailsOpts = [];
  mailsOpts.push(jsCreateElement('option', {
    attrs: {
      value: '',
      selected: true
    },
    children: ['I\'ll select a mail later']
  }));
  for (let i = 0; i < mails.length; i++) {
    mailsOpts.push(jsCreateElement('option', {
      attrs: {
        value: mails[i].id
      },
      children: [mails[i].name]
    }));
  }


  const html = jsCreateElement('div', {
    attrs: {
      style: "width: 300px;"
    },
    children: [
      jsCreateElement('div', {
        attrs: {
          class: 'headingH3 mb20 center'
        },
        children: ['Add step']
      }),
      jsCreateElement('div', {
        attrs: {
          class: 'itemBlock mb30'
        },
        children: [
          jsCreateElement('label', {
            attrs: {
              class: 'forinput'
            },
            children: ['Step name']
          }),
          jsCreateElement('input', {
            attrs: {
              type: 'text',
              id: 'flowStepName'
            }
          })
        ]
      }),
      jsCreateElement('div', {
        attrs: {
          class: 'itemBlock mb30'
        },
        children: [
          jsCreateElement('label', {
            attrs: {
              class: 'forinput'
            },
            children: ['Mail']
          }),
          jsCreateElement('select', {
            attrs: {
              id: 'flowStepMail'
            },
            children: mailsOpts
          })
        ]
      }),
      jsCreateElement('div', {
        attrs: {
          class: 'itemBlock mb30'
        },
        children: [
          jsCreateElement('label', {
            attrs: {
              class: 'forinput'
            },
            children: ['Mail subject']
          }),
          jsCreateElement('input', {
            attrs: {
              type: 'text',
              id: 'flowStepSubject'
            }
          })
        ]
      }),
      jsCreateElement('div', {
        attrs: {
          class: 'itemBlock mb30'
        },
        children: [
          jsCreateElement('label', {
            attrs: {
              class: 'forinput'
            },
            children: ['Trigger']
          }),
          jsCreateElement('select', {
            attrs: {
              id: 'flowStepTrigger'
            },
            children: [
              jsCreateElement('option', {
                attrs: {
                  value: 'delay'
                },
                children: ['Delay']
              }),
              jsCreateElement('option', {
                attrs: {
                  value: 'open'
                },
                children: ['Open previous mail']
              }),
              jsCreateElement('option', {
                attrs: {
                  value: 'click'
                },
                children: ['Click link in previous mail']
              }),
              jsCreateElement('option', {
                attrs: {
                  value: 'time'
                },
                children: ['Specific time']
              })
            ]
          })
        ]
      }),
      jsCreateElement('div', {
        attrs: {
          class: 'itemBlock mb30'
        },
        children: [
          jsCreateElement('label', {
            attrs: {
              class: 'forinput'
            },
            children: ['Delay minutes']
          }),
          jsCreateElement('input', {
            attrs: {
              type: 'number',
              id: 'flowStepDelay',
              value: '60',
              min: '10'
            }
          }),
          jsCreateElement('input', {
            attrs: {
              type: 'time',
              id: 'flowStepTime',
              value: '',
              style: 'display: none;'
            }
          }),
          jsCreateElement('div', {
            attrs: {
              style: "font-size: 12px;"
            },
            children: ['Minimum time is 2 minutes. Emails will be scheduled as soon as the step is added.']
          })
        ]
      }),
      jsCreateElement('div', {
        children: [
          jsCreateElement('button', {
            attrs: {
              class: 'buttonIcon mt20',
              onclick: 'addFlowStepDo()'
            },
            rawHtml: [
              '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v6m3-3H9m12 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" /></svg><div style="margin-left: 5px;">Add step</div>'
            ]
          })
        ]
      })
    ]
  });
  rawModalLoader(jsRender(html));
  labelFloater();
  setTimeout(() => {
    dqs("#flowStepName").focus();

    // Set the trigger type to delay by default
    dqs("#flowStepTrigger").addEventListener("change", function() {
      if (this.value === "time") {
        dqs("#flowStepTime").style.display = "";
        dqs("#flowStepDelay").style.display = "none";
      } else {
        dqs("#flowStepTime").style.display = "none";
        dqs("#flowStepDelay").style.display = "";
      }
    });
  }, 100);
}


function addFlowStepDo() {
  let
    name = dqs("#flowStepName").value,
    mailID = dqs("#flowStepMail").value,
    subject = dqs("#flowStepSubject").value,
    trigger = dqs("#flowStepTrigger").value,
    delay = dqs("#flowStepDelay").value,
    time = dqs("#flowStepTime").value;

  fetch("/api/flow_steps/create", {
    method: "POST",
    body: new URLSearchParams({
      flowID: globalFlowID,
      name: name,
      mailID: mailID,
      subject: subject,
      trigger: trigger,
      delay: delay,
      scheduledTime: time
    })
  })
  .then(manageErrors)
  .then(() => {
    dqs(".modalpop").remove();
    openFlow(globalFlowID);
  });
}


// -- Update flow step
function updateFlowStep(flowStepID) {
  let
    mailID = dqs("#flowStepMail_" + flowStepID).value,
    delayMinutes = dqs("#flowStepDelay_" + flowStepID).value,
    subject = dqs("#flowStepSubject_" + flowStepID).value,
    triggerType = dqs("#flowStepTrigger_" + flowStepID).value,
    scheduledTime = dqs("#flowStepTime_" + flowStepID).value;

  fetch("/api/flow_steps/update", {
    method: "POST",
    body: new URLSearchParams({
      flowStepID: flowStepID,
      mailID: mailID,
      delayMinutes: delayMinutes,
      subject: subject,
      trigger: triggerType,
      scheduledTime: scheduledTime
    })
  })
  .then(manageErrors);
}


// -- Flow stats
function openStepStats(stepID) {
  console.log("openStepStats", stepID);

  const html = jsCreateElement('div', {
    children: [
      jsCreateElement('div', {
        attrs: {
          class: 'headingH3 mb20 center'
        },
        children: ['Step stats']
      }),
      jsCreateElement('div', {
        attrs: {
          id: "stepStats_" + stepID
        }
      })
    ]
  });

  rawModalLoader(jsRender(html));

  var objTableStepStats = new Tabulator("#stepStats_" + stepID, {
    height:"70vh",
    layout:"fitColumns",
    ajaxURL:"/api/flow_steps/stats/contacts?flowStepID=" + stepID,
    progressiveLoad:"scroll",
    columns:[
      {title:"Status", field:"status", width:200},
      {title:"Contact", field:"user_email", width:200},
      {title:"Sent At", field:"sent_at", width:200},
      {title:"Opened times", field:"open_count", width:200},
      {title:"Scheduled for", field:"scheduled_for", width:200},
    ],
  });

  objTableStepStats.on("rowClick", function(e, row){
    loadContact(row.getData().user_id);
    dqs(".modalpop").remove();
  });

}


// -- Flow step settings
function settingsFlowStep(flowStepID) {

  // Either delete (removeFlowStep) or change step number (changeFlowStepNumber)
  const html = jsCreateElement('div', {
    children: [
      jsCreateElement('div', {
        attrs: {
          class: 'headingH3 mb20 center'
        },
        children: ['Settings']
      }),
      jsCreateElement('div', {
        attrs: {
          style: "font-size: 12px;margin:20px;"
        },
        children: [
          'Change the step number or remove this step.'
        ]
      }),
      jsCreateElement('div', {
        children: [
          jsCreateElement('button', {
            attrs: {
              class: 'buttonIcon mb20',
              onclick: 'removeFlowStep(' + flowStepID + ')'
            },
            rawHtml: [
              '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" /></svg><div style="margin-left: 5px;">Remove step</div>'
            ]
          }),
          jsCreateElement('button', {
            attrs: {
              class: 'buttonIcon',
              onclick: 'changeFlowStepNumber(' + flowStepID + ')'
            },
            rawHtml: [
              '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="M8.242 5.992h12m-12 6.003H20.24m-12 5.999h12M4.117 7.495v-3.75H2.99m1.125 3.75H2.99m1.125 0H5.24m-1.92 2.577a1.125 1.125 0 1 1 1.591 1.59l-1.83 1.83h2.16M2.99 15.745h1.125a1.125 1.125 0 0 1 0 2.25H3.74m0-.002h.375a1.125 1.125 0 0 1 0 2.25H2.99" /></svg><div style="margin-left: 5px;">Change step number</div>'
            ]
          })
        ]
      })
    ]
  });

  rawModalLoader(jsRender(html));

}


function removeFlowStep(flowStepID) {
  fetch("/api/flow_steps/delete?flowStepID=" + flowStepID, {
    method: "DELETE"
  })
  .then(manageErrors)
  .then(() => {
    dqs(".modalpop").remove();
    openFlow(globalFlowID);
  });
}


// -- Change step number
function changeFlowStepNumber(flowStepID) {

  let currentStep = globalFlowStepsData.find(step => step.id == flowStepID).step_number;

  const html = jsCreateElement('div', {
    attrs: {
      style: "max-width: 400px;"
    },
    children: [
      jsCreateElement('div', {
        attrs: {
          class: 'headingH3 mb20 center'
        },
        children: ['WARNING']
      }),
      jsCreateElement('div', {
        attrs: {
          style: "font-size: 12px;margin:20px;",
          class: 'center'
        },
        rawHtml: [
          '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z" /></svg><br>Changing the step number will affect the flow and also change the analytics.'
        ]
      }),
      jsCreateElement('div', {
        attrs: {
          style: "font-size: 12px;margin:20px;"
        },
        children: [
          'Changing a step to a lower number (e.g. from 4 to 2) will move all current contacts on step 3 and 4 to step 5.'
        ]
      }),
      jsCreateElement('div', {
        attrs: {
          style: "font-size: 12px;margin:20px;"
        },
        children: [
          'Changing a step to a higher number (e.g. from 3 to 5) will move all current contacts on step 4  and 5 to step 6 (if any).'
        ]
      }),
      jsCreateElement('div', {
        attrs: {
          style: "font-size: 12px;margin:20px;"
        },
        children: [
          'Are you sure you want to change the step number?'
        ]
      }),
      jsCreateElement('input', {
        attrs: {
          type: 'number',
          id: 'newStepNumber',
          value: currentStep
        }
      }),
      jsCreateElement('div', {
        children: [
          jsCreateElement('button', {
            attrs: {
              class: 'buttonIcon mt20',
              onclick: 'changeFlowStepNumberDo(' + flowStepID + ')'
            },
            rawHtml: [
              '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v6m3-3H9m12 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" /></svg><div style="margin-left: 5px;">Change step number</div>'
            ]
          })
        ]
      })
    ]
  });

  rawModalLoader(jsRender(html));
}


function changeFlowStepNumberDo(flowStepID) {
  let newStepNumber = dqs("#newStepNumber").value;

  fetch("/api/flow_steps/update/step", {
    method: "POST",
    body: new URLSearchParams({
      flowStepID: flowStepID,
      newStepNumber: newStepNumber
    })
  })
  .then(manageErrors)
  .then(() => {
    dqs(".modalpop").remove();
    openFlow(globalFlowID);
  });
}

