angular.module 'equationSandbox'

	.controller 'CreatorController', ['$scope', '$http', ($scope, $http) ->
		"use strict";

		### Initialize class variables ###

		_title = _qset = null

		DEFAULT_EQUATION = 'y=2^x+a'
		PLAYER_WIDTH = 700
		PLAYER_HEIGHT = 500
		UPDATE_DEBOUNCE_DELAY_MS = 500

		updateTimeoutId = -1

		$scope.latex = ''
		$scope.expression = ''

		$scope.parseError = no
		$scope.boundsError = no
		$scope.waiting = no

		$scope.bounds =
			x:
				min: -10
				max: 10
			y:
				min: -10
				max: 10

		### Materia Interface Methods ###

		$scope.initNewWidget = (widget, baseUrl) -> true

		$scope.onSaveComplete = (title, widget, qset, version) -> true

		$scope.onQuestionImportComplete = (items) -> true

		$scope.onMediaImportComplete  = (media) -> null

		$scope.initExistingWidget = (title,widget,qset,version,baseUrl) ->
			try 
				_qset = qset
				_latex = qset.data

			catch e
				console.log "initExistingWidget error: ", e

		$scope.onSaveClicked = (mode = 'save') ->
			try
				if !_buildSaveData()
					console.log 'Fix errors before saving'
					return

				Materia.CreatorCore.save _title, _qset
			catch e 
				console.log "onSaveClicked error: ", e

		### Private methods ###

		_buildSaveData = ->
			try
				if !_qset? then _qset = {}

				_title = 'TITLE PLACEHOLDER'

				_validateBounds()
				return null if $scope.parseError

				_qset.version = 1
				_qset =
					latex: $scope.latex
					bounds: $scope.bounds
			catch e
				console.log "_buildSaveData error: ", e
				return null

		_validateBounds = ->
			try
				bounds = [xmin, ymax, xmax, ymin] = [$scope.bounds.x.min,$scope.bounds.y.max,$scope.bounds.x.max,$scope.bounds.y.min]
			
				# non-numeric entry
				if bounds.some( (el) -> return (isNaN(el) or !el?))
					$scope.boundsError = yes
					$scope.bnds_errorMsg = 'One of the bounds is not a number.'
					return null

				# out of order
				if xmin > xmax or ymin > ymax
					$scope.boundsError = yes
					$scope.bnds_errorMsg = 'The bounds are out of order.'
					return null

				# equality
				if xmin is xmax or ymin is ymax
					$scope.boundsError = yes
					$scope.bnds_errorMsg = 'One interval represents a point.'
					return null

				$scope.boundsError = no
				$scope.bnds_errorMsg = ''
				$scope.bounds

			catch e
				console.log "_validateBounds error: ", e

		### Scope Methods ###

		$scope.onBoundsChange = ->
			bounds = _validateBounds() # bounds are null if invalid
			return if !bounds?
			$scope.bounds = bounds

		# we instantly update if there's a parse error so the user could
		# find a fix, but otherwise we wait a bit so we don't flash them
		# with error messages while they are composing the equation
		$scope.onKeyup = (e) ->
			try 
				if e.target.classList.contains 'graph-bounds-input'
					return

				# grab the latex (and do nothing if it hasn't changed, i.e. user pressed <-)
				lastLatex = $scope.latex
				$scope.latex = $('#eq-input').mathquill('latex')
				return if lastLatex is $scope.latex

				if $scope.parseError
					$scope.waiting = no
					return

				$scope.waiting = yes

				clearTimeout updateTimeoutId
				updateTimeoutId = setTimeout ->
					$scope.waiting = no
					$scope.$apply()
				, UPDATE_DEBOUNCE_DELAY_MS

			catch e
				console.log "onKeyup error: ", e

		$scope.$on "$includeContentLoaded", (evt, url) ->
			try
				jQuery('#eq-demo-input').mathquill()
				$scope.latex = DEFAULT_EQUATION
				$('#eq-input').mathquill('latex', $scope.latex)
				$scope.$broadcast("SendDown")
			catch e
				console.log "init error: ", e

		Materia.CreatorCore.start $scope
	]