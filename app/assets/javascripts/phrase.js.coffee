# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

phraser = angular.module 'phraser', []

phraser.controller 'PhraseBuilder', ($scope, $http) ->
	$scope.words = ['le']
	$scope.fetchNextWords = (word) ->
		$http.get("/phrase/next?word=#{word}").success (data) ->
			$scope.nextWords = data
	$scope.selectWord = (word) ->
		$scope.words.push word
		$scope.fetchNextWords word
	lastWord = $scope.words[$scope.words.length - 1] 
	$scope.fetchNextWords lastWord
