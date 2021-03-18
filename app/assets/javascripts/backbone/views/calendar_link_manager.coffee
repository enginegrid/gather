Gather.Views.CalendarLinkManager = Backbone.View.extend
  initialize: (options) ->
    @calendarView = options.calendarView
    @listenTo(@calendarView, 'viewRender', @onViewRender.bind(this))

  onViewRender: ->
    viewType = @calendarView.viewType()
    currentDate = @calendarView.currentDate()
    qsParams = "view=#{viewType}&date=#{currentDate}"
    @updatePermalink(qsParams)
    @updateOtherCalendarLinks(qsParams)

  updatePermalink: (qsParams) ->
    @updateLink($('#permalink'), qsParams)

  updateOtherCalendarLinks: (qsParams) ->
    @$('.calendar-link').each (_, el) => @updateLink(el, qsParams)

  updateLink: (link, qsParams) ->
    href = $(link).attr('href').replace(/(calendar_id=[^&]+).*$/, (_, $1) -> "#{$1}&#{qsParams}")
    $(link).attr('href', href)
