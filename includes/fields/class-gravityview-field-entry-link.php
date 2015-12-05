<?php

/**
 * Add custom options for entry_link fields
 */
class GravityView_Field_Entry_Link extends GravityView_Field {

	var $name = 'entry_link';

	var $label = 'Link to Entry';

	var $contexts = array( 'multiple' );

	public function __construct() {
		$this->label = esc_attr__( 'Link to Entry', 'gravityview' );
		$this->description = __('A dedicated link to the single entry with customizable text.', 'gravityview');
		parent::__construct();
	}

	function field_options( $field_options, $template_id, $field_id, $context, $input_type ) {

		// Always a link!
		unset( $field_options['show_as_link'], $field_options['search_filter'] );

		if( 'edit' === $context ) {
			return $field_options;
		}

		$add_options = array();
		$add_options['entry_link_text'] = array(
			'type' => 'text',
			'label' => __( 'Link Text:', 'gravityview' ),
			'desc' => NULL,
			'value' => __('View Details', 'gravityview'),
			'merge_tags' => true,
		);

		return $add_options + $field_options;
	}

}

new GravityView_Field_Entry_Link;
