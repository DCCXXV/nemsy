import { PUBLIC_API_BASE_URL } from '$env/static/public';
import { redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';
import type { User } from '$lib/types';

export const load: LayoutServerLoad = async ({ fetch, url }) => {
	let me: User | null = null;

	try {
		const res = await fetch(`${PUBLIC_API_BASE_URL}/api/me`, {
			credentials: 'include'
		});

		if (res.ok) {
			me = await res.json();
		}
	} catch (err) {
		console.error('Error fetching /me:', err);
	}

	const isAuthPage = url.pathname.startsWith('/auth');

	if (me && me.studyId == null && !isAuthPage) {
		redirect(302, '/auth');
	}

	return { me };
};
