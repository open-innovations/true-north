/*
	OI collapsable section v1.1
	The first child of the section will be the visible heading
*/
(function(root){

	function initialiseToggleSections() {
		// Find all the toggle-section elements
		const toggleSections = document.querySelectorAll('.toggle-section');
		
		// Iterate through each one
		Array.prototype.forEach.call(toggleSections, toggleSection => {
			// Find the heading
			const heading = toggleSection.firstElementChild;
			// TODO Check if heading is a heading?

			// Update the innerHTML with a button and SVG indicator
			heading.innerHTML = `<button aria-expanded="false">${heading.textContent}
			<svg aria-hidden="true" focusable="false" viewBox="0 0 10 10">
			<rect class="vert" height="8" width="2" y="1" x="4"/>
			<rect height="2" width="8" y="4" x="1"/>
			</svg></button>`;
			
			// Create a div to contain the hideable stuff
			const container = document.createElement('div');
			// ...and set it to hidden
			container.hidden = true;
			// Add all the heading siblings to the container
			const siblings = [...heading.parentNode.children].filter((child) => child !== heading);
			if(siblings) siblings.forEach(el => { container.appendChild(el); });
			// Add the container to the section
			toggleSection.appendChild(container);
			
			// Grab the button
			const btn = heading.querySelector('button');
			
			// Attach an onclick handler
			btn.onclick = () => {
				// Get the state of the aria-expanded property
				const expanded = btn.getAttribute('aria-expanded') === 'true' || false;
				// Flip the polarity of the aria-expanded property
				btn.setAttribute('aria-expanded', !expanded);
				// And set the hidden status of the container
				container.hidden = expanded;
			}
		})
	}
		
	addEventListener('DOMContentLoaded', () => { initialiseToggleSections(); });

})(window || this);