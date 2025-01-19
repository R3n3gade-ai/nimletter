

let chartDom = dqs('#work');
chartDom.innerHTML = '';
// chartDom.appendChild(
//   jsRender(jsCreateElement('div', {
//     attrs: {
//       id: 'workChart',
//       style: 'height: 400px;margin-top: 20px;'
//     }
//   }))
// );
chartDom.appendChild(
  jsRender(
    jsCreateElement('div', {
      attrs: {
        style: 'display: grid;grid-template-columns: 80% 20%; grid-gap: 40px;max-width:1800px;margin-top: 20px;'
      },
      children: [
        jsCreateElement('div', {
          attrs: {
            id: 'workChart',
            style: 'height: 60vh;'
          }
        }),
        jsCreateElement('div', {
          attrs: {
            id: 'percentageChart',
            style: 'height: 60vh;'
          }
        })
      ]
    })
  ));
// chartDom.appendChild(
//   jsRender(
//     jsCreateElement('div', {
//       attrs: {
//         style: 'display: flex;justify-content: space-between;'
//       },
//       children: [
//         jsCreateElement('div', {
//           attrs: {
//             id: 'statsChart',
//             style: 'height: 300px;margin-top: 20px;width: 50%;'
//           }
//         }),
//         jsCreateElement('div', {
//           attrs: {
//             id: 'percentageChart',
//             style: 'height: 300px;margin-top: 20px;width: 50%;'
//           }
//         })
//       ]
//     })
//   ));

var workChart = echarts.init(dqs('#workChart'));
// var statsChart = echarts.init(dqs('#statsChart'));
var percentageChart = echarts.init(dqs('#percentageChart'));

fetch('/api/analytics/mails', {
  method: 'GET'
})
.then(manageErrors)
.then(response => response.json())
.then(data => {
  chartLine(data);
});

fetch('/api/analytics/stats', {
  method: 'GET'
})
.then(manageErrors)
.then(response => response.json())
.then(data => {
  chartPie(data);
});

function chartLine(data) {
  let option = {
    title: {
      text: 'Running stats',
      textStyle: {
        fontWeight : 'normal',
      }
    },
    tooltip: {
      trigger: 'axis'
    },
    legend: {
      data: ['Pending', 'Sent', 'Bounced', 'Complaints', 'Opened', 'Clicked'],
      left: 'left',
      top: 'middle',
      orient: 'vertical'
    },
    xAxis: {
      type: 'category',
      data: data.days
    },
    yAxis: {
      type: 'value'
    },
    series: [
      {
        data: data.pending,
        type: 'line',
        smooth: true,
        name: 'Pending',
        itemStyle: {
          color: '#b3bac5'
        },
        areaStyle: {}
      },
      {
        data: data.sent,
        type: 'line',
        smooth: true,
        name: 'Sent',
        itemStyle: {
          color: '#91cc75'
        },
        areaStyle: {
          opacity: 0.3
        }
      },
      {
        data: data.bounced,
        type: 'line',
        smooth: true,
        name: 'Bounced',
        itemStyle: {
          color: '#ff7452'
        }
      },
      {
        data: data.complained,
        type: 'line',
        smooth: true,
        name: 'Complaints',
        itemStyle: {
          color: '#ffc400'
        }
      },
      {
        data: data.opened,
        type: 'line',
        smooth: true,
        name: 'Opened',
        itemStyle: {
          color: '#57d9a3'
        }
      },
      {
        data: data.clicked,
        type: 'line',
        smooth: true,
        name: 'Clicked',
        itemStyle: {
          color: '#a90000'
        }
      }
    ]
  };
  option && workChart.setOption(option);
}

function chartBar(data) {
  let option = {
    xAxis: {
      type: 'category',
      data: ['Sent', 'Opened', 'Clicked', 'Bounced', 'Complained'],
    },
    yAxis: {
      type: 'value'
    },
    series: [
      {
        data: [
          {
            value: data.total_sent,
            itemStyle: {
              color: 'var(--colorN60)'
            }
          },
          {
            value: data.total_opened,
            itemStyle: {
              color: 'var(--colorG200)'
            }
          },
          {
            value: data.total_clicked,
            itemStyle: {
              color: '#a90000'
            }
          },
          {
            value: data.total_bounced,
            itemStyle: {
              color: 'var(--colorY200)'
            }
          },
          {
            value: data.total_complained,
            itemStyle: {
              color: 'var(--colorR200)'
            }
          },
        ],
        type: 'bar',
        barWidth: 20
      }
    ]
  };

  option && statsChart.setOption(option);
}

function chartPie(data) {

  let option2 = {
    title: {
      text: 'Stats last 30 days',
      textStyle: {
        fontWeight : 'normal',
      }
    },
    tooltip: {
      trigger: 'item'
    },
    legend: {
      left: 'left',
      top: 'middle',
      orient: 'vertical',
      data: ['Non-opened', 'Opened', 'Bounce', 'Complained']
    },
    toolbox: {
      show: true
    },
    series: [
      {
        name: 'Mails',
        type: 'pie',
        radius: ['40%', '70%'],
        avoidLabelOverlap: false,
        itemStyle: {
          borderRadius: 10,
          borderColor: '#fff',
          borderWidth: 2
        },
        label: {
          show: false,
          position: 'center'
        },
        emphasis: {
          label: {
            show: true,
            fontSize: 40,
            fontWeight: 'bold'
          }
        },
        labelLine: {
          show: false
        },
        data: [{
            value: (data.total_sent - data.total_opened - data.total_bounced - data.total_complained),
            name: 'Non-opened',
            itemStyle: {
              color: '#b3bac5'
            }
          },
          {
            value: data.total_opened,
            name: 'Opened',
            itemStyle: {
              color: '#57d9a3'
            }
          },
          {
            value: data.total_bounced,
            name: 'Bounce',
            itemStyle: {
              color: '#ff7452'
            }
          },
          {
            value: data.total_complained,
            name: 'Complained',
            itemStyle: {
              color: '#ffc400'
            }
          },
        ]
      }
    ]
  };

  option2 && percentageChart.setOption(option2);
}