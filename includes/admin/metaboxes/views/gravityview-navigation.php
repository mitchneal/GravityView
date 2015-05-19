<?php
/**
 * Display the tab navigation for the Settings metabox
 *
 * @package GravityView
 * @subpackage Gravityview/admin/metaboxes/views
 * @since 1.8
 *
 * @global GravityView_Metabox_Tab[] $metaboxes
 * @global WP_Post $post
 */

?>
<ul class="ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all">
	<?php

	foreach( $metaboxes as $metabox ) {
		$title = esc_html( trim( rtrim( $metabox->title ) ) );
		$class = !isset( $class ) ? 'nav-tab-active' : '';
	?>
	<li class="ui-state-default">
		<a class="nav-tab ui-tabs-anchor <?php echo $class; ?>" href="#<?php echo esc_attr( $metabox->id ); ?>">
			<span class="<?php echo $metabox->icon_class_name; ?>" title="<?php echo $title; ?>"></span>&nbsp;
			<span class="gv-nav-tab-title"><?php echo $title; ?></span>
		</a>
	</li>
	<?php
	}
	?>
</ul>