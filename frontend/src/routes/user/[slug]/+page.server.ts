import { PUBLIC_API_BASE_URL } from '$env/static/public';
import type { PageServerLoad } from './$types';
import type { User, Resource } from '$lib/types';

export const load: PageServerLoad = async ({ fetch, parent, params }) => {
	const { me } = await parent();
	const username = params.slug;

	let user: User | null = null;
	let resources: Resource[] = [];

	if (!me) {
		return { user, resources };
	}

	try {
		const userRes = await fetch(`${PUBLIC_API_BASE_URL}/api/users/by/${username}`, {
			credentials: 'include'
		});

		if (userRes.ok) {
			user = await userRes.json();
		}
	} catch (err) {
		console.error('Error fetching user:', err);
	}

	if (user) {
		try {
			const resourcesRes = await fetch(`${PUBLIC_API_BASE_URL}/api/resources/by/${username}`, {
				credentials: 'include'
			});
			if (resourcesRes.ok) {
				resources = await resourcesRes.json();
			}
		} catch (err) {
			console.error('Error fetching user resources:', err);
		}
	}

	return { user, resources };
};
