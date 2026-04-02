import { PUBLIC_API_BASE_URL } from '$env/static/public';
import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export interface Report {
	id: number;
	reason: string;
	createdAt: string;
	resourceId: number;
	resourceTitle: string;
	reporterId: number;
	reporterUsername: string;
	ownerId: number;
	ownerUsername: string;
}

export const load: PageServerLoad = async ({ fetch, parent }) => {
	const { me } = await parent();

	if (!me || me.role !== 'admin') {
		redirect(302, '/');
	}

	let reports: Report[] = [];
	try {
		const res = await fetch(`${PUBLIC_API_BASE_URL}/api/admin/reports`, {
			credentials: 'include'
		});
		if (res.ok) {
			const data = await res.json();
			if (Array.isArray(data)) {
				reports = data;
			}
		} else {
			console.error('Admin reports fetch failed:', res.status, await res.text());
		}
	} catch (err) {
		console.error('Error fetching reports:', err);
	}

	return { reports };
};
