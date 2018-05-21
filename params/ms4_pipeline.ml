
exports.main=main;
exports.spec=spec;

function spec() {
  return {
    inputs:[
      {
        name:'timeseries',
        optional:false
      },
      {
        name:'geom',
        optional:true
      }
    ],
    outputs:[
      {
        name:'firings_out',
        optional:false
      },
      {
        name:'filt_out',
        optional:true
      },
      {
        name:'pre_out',
        optional:true
      }
    ],
    parameters:[
      {
        name:'samplerate',
        optional:false
      },
      {
        name:'detect_sign',
        optional:false
      },
      {
        name:'detect_threshold',
        optional:true,
        default_value:3
      },
      {
        name:'adjacency_radius',
        optional:true,
        default_value:-1
      },
      {
        name:'filter',
        optional:true,
        default_value:'true'
      },
      {
        name:'whiten',
        optional:true,
        default_value:'true'
      },
      {
        name:'freq_min',
        optional:true,
        default_value:300
      },
      {
        name:'freq_max',
        optional:true,
        default_value:6000
      },
      {
        name:'clip_size',
        optional:true,
        default_value:50
      },
      {
        name:'num_workers',
        optional:true,
        default_value:0
      },
      {
        name:'detect_interval',
        optional:true,
        default_value:10
      },
      {
        name:'num_channels',
        optional:true,
        default_value:0,
        description:'Use this only if the input file is raw binary (not mda)'
      },
      {
        name:'compute_metrics',
        optional:true,
        default_value:'true'
      }
    ]
  };
}

function main(inputs,outputs,parameters,opts) {
  var pp=parameters;

  var results={};
  results.raw=inputs.timeseries;
  if (Number(pp.num_channels)) {
    results.raw=convert_to_mda(results.raw,num_channels);
  }
  results.filt=results.raw;
  if (pp.filter=='true') {
    results.filt=bandpass_filter(results.filt,{samplerate:pp.samplerate,freq_min:pp.freq_min,freq_max:pp.freq_max});
  }
  results.pre=results.filt;
  if (pp.whiten=='true') {
    results.pre=whiten(results.pre,{samplerate:pp.samplerate,freq_min:pp.freq_min,freq_max:pp.freq_max});
  }

  var sort_params={
    adjacency_radius:pp.adjacency_radius,
    detect_sign:pp.detect_sign,
    detect_threshold:pp.detect_threshold,
    detect_interval:pp.detect_interval,
    clip_size:pp.clip_size,
    num_workers:pp.num_workers
  };
  results.firings=ms4alg_sort(results.pre,inputs.geom||'',sort_params);

  _MLS.setResult(outputs.firings_out,results.firings);
  if (outputs.filt_out)
    _MLS.setResult(outputs.filt_out,results.filt);
  if (outputs.pre_out)
    _MLS.setResult(outputs.pre_out,results.pre);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
function convert_to_mda(A,num_channels) {
  var params={
    format_out:'mda',
    dimensions:`${num_channels},-1`
  };
  var B=_MLS.runProcess(
    'ephys.convert_array',
    {
      input:A
    },
    {
      output:true
    },
    params,
    {}
  );
  return B.output;
}

function bandpass_filter(A,params) {
  var B=_MLS.runProcess(
    'ephys.bandpass_filter',
    {
      timeseries:A
    },
    {
      timeseries_out:true
    },
    params,
    {}
  );
  return B.timeseries_out; //same as B['timeseries_out']
}
function whiten(A) {
  var B=_MLS.runProcess(
    'ephys.whiten',
    {
      timeseries:A
    },
    {
      timeseries_out:true
    },
    {}
  );
  return B.timeseries_out;
}
function ms4alg_sort(timeseries,geom,params) {
  var B=_MLS.runProcess(
    'ms4alg.sort',
    {
      timeseries:timeseries,
      geom:geom||''
    },
    {
      firings_out:true
    },
    params,
    {}
  );
  return B.firings_out;
}
