<?php
/**
 * @file class-gravityview-field-sequence.php
 * @package GravityView
 * @subpackage includes\fields
 */

/**
 * Add a sequence field.
 * @since develop
 */
class GravityView_Field_Sequence extends GravityView_Field {

	var $name = 'sequence';

	var $contexts = array( 'single', 'multiple' );

	/**
	 * @var bool
	 */
	var $is_sortable = false;

	/**
	 * @var bool
	 */
	var $is_searchable = false;

	/**
	 * @var bool
	 */
	var $is_numeric = true;

	var $_custom_merge_tag = 'sequence';

	var $group = 'gravityview';

	public function __construct() {

		$this->label = esc_html__( 'Result Number', 'gravityview' );

		parent::__construct();
	}

	function field_options( $field_options, $template_id, $field_id, $context, $input_type ) {

		unset ( $field_options['search_filter'] );

		$new_fields = array(
			'start' => array(
				'type' => 'number',
				'label' => __( 'First row number', 'gravityview' ),
				'value' => '1',
			),
			'reverse' => array(
				'type' => 'checkbox',
				'label' => __( 'Reverse the sequence', 'gravityview' ),
				'tooltip' => __( 'Output row numbers in reverse order.', 'gravityview' ),
				'value' => '',
			),
		);

		return $new_fields + $field_options;
	}

	/**
	 * Replace {sequence} Merge Tags inside Custom Content fields
	 *
	 * TODO:
	 * - Add support for `:start:[1-9]+` modifier
	 * - Add support for `:reverse` modifier
	 * - Find a better way to infer current View data (without using legacy code)
	 * - Add tests
	 *
	 * @param array $matches
	 * @param string $text
	 * @param array $form
	 * @param array $entry
	 * @param bool $url_encode
	 * @param bool $esc_html
	 *
	 * @return string
	 */
	public function replace_merge_tag( $matches = array(), $text = '', $form = array(), $entry = array(), $url_encode = false, $esc_html = false ) {

		$view_data = gravityview_get_current_view_data(); // TODO: Don't use legacy code...

		if ( empty( $view_data ) ) {
			return '';
		}

		$gv_field = \GV\Internal_Field::by_id( 'sequence' );
		$gv_field->reverse = false; // TODO: Allow overriding via Merge Tag modifiers
		$gv_field->start = 1; // TODO: Allow overriding via Merge Tag modifiers

		$context = new \GV\Template_Context();
		$context->view = \GV\View::by_id( $view_data['view_id'] );
		$context->entry = \GV\GF_Entry::from_entry( $entry );
		$context->field = $gv_field;

		return str_replace( '{sequence}', $this->get_sequence( $context ), $text );
	}

	/**
	 * Calculate the current sequence number for the context.
	 *
	 * @param  \GV\Template_Context $context The context.
	 *
	 * @return int The sequence number for the field/entry within the view results.
	 */
	public function get_sequence( $context ) {
		static $startlines = array();

		$context_key = md5( json_encode(
			array(
				$context->view->ID,
				\GV\Utils::get( $context, 'field/UID' ), //TODO: Generate UID when using Merge Tag
			)
		) );

		/**
		 * Figure out the starting number.
		 */
		if ( $context->request && $entry = $context->request->is_entry() ) {
			$sql_query = '';
			add_filter( 'gform_gf_query_sql', $callback = function( $sql ) use ( &$sql_query ) {
				$sql_query = $sql;
				return $sql;
			} );

			$total = $context->view->get_entries()->total();
			remove_filter( 'gform_gf_query_sql', $callback );

			unset( $sql_query['paginate'] );

			global $wpdb;

			foreach ( $wpdb->get_results( implode( ' ', $sql_query ), ARRAY_A ) as $n => $result ) {
				if ( in_array( $entry->ID, $result ) ) {
					return $context->field->reverse ? ( $total - $n ) : ( $n + 1 );
				}
			}

			return 0;
		} elseif ( ! isset( $startlines[ $context_key ] ) ) {
			$pagenum  = max( 0, \GV\Utils::_GET( 'pagenum', 1 ) - 1 );
			$pagesize = $context->view->settings->get( 'page_size', 25 );

			if ( $context->field->reverse ) {
				$startlines[ $context_key ] = $context->view->get_entries()->total() - ( $pagenum * $pagesize );
				$startlines[ $context_key ] += $context->field->start - 1;
			} else {
				$startlines[ $context_key ] = ( $pagenum * $pagesize ) + $context->field->start;
			}
		}

		return $context->field->reverse ? $startlines[ $context_key ]-- : $startlines[ $context_key ]++;
	}
}

new GravityView_Field_Sequence;