(function($) {

var add_class = (function() {
	return document.createElement('div').classList ? function(target, class_name) {
		target.classList.add(class_name);
	} : function(target, class_name) {
		target.className += ' ' + class_name;
	};
})();

var kaomoji = {
	  chunk_size: /iPhone/.test(navigator.userAgent) ? 30 : 100

	, activate: function() {
		var   items = $('span.kaomoji').toArray()
			, chunk_size = this.chunk_size
			, onprogress
			, oncomplete
			, total = items.length
			, count = 0;

		if (arguments.length === 2) {
			onprogress = arguments[0];
			oncomplete = arguments[1];
		} else {
			onprogress = null;
			oncomplete = arguments[0];
		}

		!function wrapper() {
			if (items.length === 0) {
				oncomplete && oncomplete();
				return;
			}

			var chunk = items.splice(0, chunk_size);
			count += chunk.length;

			while (chunk.length)
				add_class(chunk.shift(), 'active');

			// chunk_size = 10;
			setTimeout(wrapper, 30);
			onprogress && onprogress(count, total);
		}();
	}
	, inactivate: function() {
		$('span.kaomoji').removeClass('active');
	}
};

$(function() {
	setTimeout(function() {
		var $progress = $('.progress');

		kaomoji.activate(function(current, total) {
			$progress.text(Math.round((current / total) * 100) + '%');
		}, function() {
			setTimeout(function() {
				$('h1 span.loading').fadeOut('fast');
			}, 1000);
		});
	}, 0);
		

	$('#select').on('click', function(e) {
		e.preventDefault();
		e.stopPropagation();
		
		var $selected = $('span[data-selected="true"]')
			, result = [];
		
		if (!$selected.size()) return;
		
		$selected.each(function(index, selected) {
			result.push($(selected).text());
		});
		
		$('#selected').val(result.join('\n'));
		$('#kaomoji').hide();
		$('#kaomoji-selected').show();
		kaomoji.inactivate();
	});
	
	$('#back').on('click', function(e) {
		e.preventDefault();
		e.stopPropagation();
		$('#kaomoji-selected').hide();
		$('#kaomoji').show();
		kaomoji.activate();
	});
	
	'createTouch' in document ? (function() {
		var $win = $(window)
			, $select = $('#select').css({'position': 'absolute', 'bottom': 'auto'})
			, select_height = $select.height();
		
		$win.on('scroll', function() {
			var bottom = window.pageYOffset + window.innerHeight - select_height;
			$select.css('top', bottom + 'px');
		}).trigger('scroll');
		
		var id = null
			, target = null
			, start_time = 0
			, start_offset_x = 0
			, start_offset_y = 0;
		
		$('span.kaomoji').on('touchstart', function(e) {
			var oe = e.originalEvent;
			
			if (id !== null || oe.touches.length > 1) return;
			
			var touch = oe.touches[0];
			
			id = touch.identifier;
			target = this;
			start_time = Date.now();
			// start_offset_x = window.pageXOffset;
			start_offset_y = window.pageYOffset;
		}).on('touchend', function(e) {
			if (
				window.getSelection().rangeCount ||
				target !== this ||
				Date.now() - start_time > 400 ||
				// Math.max(start_offset_x, window.pageXOffset) - Math.min(start_offset_x, window.pageXOffset) > 10 ||
				Math.max(start_offset_y, window.pageYOffset) - Math.min(start_offset_y, window.pageYOffset) > 10
			) {
				id = target = null;
				start_offset_x = start_offset_y = start_time = 0;
				return;
			}
			
			var oe = e.originalEvent;
			
			if (oe.touches.length === 0) {
				id = target = null;
				start_offset_x = start_offset_y = start_time = 0;
				toggle_selection(this);
			} else {
				var touch = get_touch(id, oe.targetTouches);
				if (!touch) return;
				id = target = null;
				start_offset_x = start_offset_y = start_time = 0;
				toggle_selection(this);
			}
		});
		
		function get_touch(id, touches) {
			for(var i = 0, j = touches.length; i < j; i ++) {
				if (id === touches[i].identifier) return touches[i];
			}
			return null;
		}
	})() : (function() {
		var start_x = 0
			, start_y = 0
			, cancel = false;
		
		$('span.kaomoji').on('mousedown', function(e) {
			start_x = e.pageX;
			start_y = e.pageY;
			var selection = window.getSelection();
			if (selection.rangeCount > 1) {
				cancel = true;
			} else if (selection.rangeCount === 1) {
				var range = selection.getRangeAt(0);
				if (range.startOffset !== range.endOffset) {
					cancel = true;
				} else if (range.startOffset === 0) {
					cancel = range.startContainer !== range.endContainer;
				} else {
					cancel = false;
				}
			} else {
				cancel = false;
			}
		}).on('mouseup', function(e) {
			if (
				!cancel &&
				Math.max(start_x, e.pageX) - Math.min(start_x, e.pageX) < 10 &&
				Math.max(start_y, e.pageY) - Math.min(start_y, e.pageY) < 10
			) {
				e.preventDefault();
				e.stopPropagation();
				toggle_selection(this);
			}
		});
	})();
	
	function toggle_selection(target) {
		var $target = $(target)
			, selected = $target.attr('data-selected') === 'true';
		
		if (selected) {
			$target.attr('data-selected', 'false').removeClass('selected');
		} else {
			$target.attr('data-selected', 'true').addClass('selected');
		}
	}
});

})(jQuery);