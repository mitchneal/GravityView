<?php

/**
 * Add custom options for date fields
 */
class GravityView_Field_Post_Content extends GravityView_Field {

	var $name = 'post_content';

	var $search_operators = array( 'is', 'isnot', 'contains', 'starts_with', 'ends_with' );

	var $_gf_field_class_name = 'GF_Field_Post_Content';

	var $label = 'Body';

	public function __construct() {
		$this->label = esc_attr__( 'Body', 'gravityview' );
		parent::__construct();
	}

	function field_options( $field_options, $template_id, $field_id, $context, $input_type ) {

		unset( $field_options['show_as_link'] );

		if( 'edit' === $context ) {
			return $field_options;
		}

		$this->add_field_support('dynamic_data', $field_options );

		return $field_options;
	}

}

new GravityView_Field_Post_Content;
