$(document).ready(function() {
  var refresh_button = $('.refresh-set-source')
  var base_url = $('#harvester_base_url')
  var external_set_select = $("#harvester_external_set_id")
  var initial_base_url = base_url.val()

  // handle refreshing/loading of external setes via button click
  $('body').on('click', '.refresh-set-source', function(e) {
    e.preventDefault()

    handleSourceLoad(refresh_button, base_url, external_set_select)
  })

  // handle refreshing/loading of external sets via blur event for the base_url field
  $('body').on('blur', '#harvester_base_url', function(e) {
    e.preventDefault()

    // ensure we don't make another query if the value is the same -- this can be forced by clicking the refresh button
    if (initial_base_url != base_url.val()) {
      handleSourceLoad(refresh_button, base_url, external_set_select)
      initial_base_url = base_url.val()
    }
  })
});

function handleSourceLoad(refresh_button, base_url, external_set_select) {
  if (base_url.val() == "") { // ignore empty base_url value
    return
  }

  var initial_button_text = refresh_button.html()

  refresh_button.html('Refreshing...')
  refresh_button.attr('disabled', true)

  $.post('/harvesters/external_sets', {
    base_url: base_url.val(),
  }, function(res) {
    if (!res.error) {
      genExternalSetOptions(external_set_select, res.sets) // sets is [[name, spec]...]
    } else {
      setError(external_set_select, res.error)
    }

    refresh_button.html(initial_button_text)
    refresh_button.attr('disabled', false)
  })
}

function genExternalSetOptions(selector, sets) {
  out = '<option value="">- Select One -</option>'

  out += sets.map(function(set) {
    return '<option value="'+set[1]+'">'+set[0]+'</option>'
  })

  selector.html(out)
  selector.attr('disabled', false)
}

function setError(selector, error) {
  selector.html('<option value="none">Error - Please enter Base URL and try again</option>')
  selector.attr('disabled', true)
}
